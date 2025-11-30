require "thor"
require "fileutils"

module Sitepress
  # Command line interface for compiling Sitepress sites.
  class CLI < Thor
    # Default port address for server port.
    SERVER_PORT = 8080

    # Default address is public to all IPs.
    SERVER_BIND_ADDRESS = "127.0.0.1".freeze

    # Default build path for compiler.
    COMPILE_TARGET_PATH = "./build".freeze

    # Display detailed error messages to the developer. Useful for development environments
    # where the error should be displayed to the developer so they can debug errors.
    SERVER_SITE_ERROR_REPORTING = true

    # Reload the site between requests, useful for development environments when
    # the site has to be rebuilt between requests. Disable in production environments
    # to run the site faster.
    SERVER_SITE_RELOADING = true

    include Thor::Actions

    source_root File.expand_path("../../../templates/default", __FILE__)

    option :bind_address, default: SERVER_BIND_ADDRESS, aliases: :a
    option :port, default: SERVER_PORT, aliases: :p, type: :numeric
    option :site_reloading, default: SERVER_SITE_RELOADING, aliases: :r, type: :boolean
    option :site_error_reporting, default: SERVER_SITE_ERROR_REPORTING, aliases: :e, type: :boolean
    desc "server", "Run preview server"
    def server
      # Now boot everything for the Rack server to pickup.
      initialize! do |app|
        # Enable Sitepress web error reporting so users have more friendly
        # error messages instead of seeing a Rails exception.
        app.config.enable_site_error_reporting = options.fetch("site_error_reporting")

        # Enable reloading the site between requests so we can see changes.
        app.config.enable_site_reloading = options.fetch("site_reloading")
      end

      # This will use whatever server is found in the user's Gemfile.
      Rack::Server.start app: app,
        Port: options.fetch("port"),
        Host: options.fetch("bind_address")
    end

    option :output_path, default: COMPILE_TARGET_PATH, type: :string
    option :fail_on_error, default: false, type: :boolean
    desc "compile", "Compile project into static pages"
    def compile
      initialize!

      logger.info "Sitepress compiling assets"
      compile_assets(target_path: options.fetch("output_path"))

      logger.info "Sitepress compiling pages"
      compiler = Compiler::Files.new \
        site: configuration.site,
        root_path: options.fetch("output_path"),
        fail_on_error: options.fetch("fail_on_error")

      begin
        compiler.compile
      ensure
        logger.info ""
        logger.info "Compilation Summary"
        logger.info "  Build path: #{compiler.root_path.expand_path}"
        logger.info "  Succeeded:  #{compiler.succeeded.count}"
        logger.info "  Failed:     #{compiler.failed.count}"
        if compiler.failed.any?
          logger.info ""
          logger.info "Failed Resources"
          compiler.failed.each do |resource|
            logger.info "  #{resource.request_path}  #{resource.asset.path}"
          end
          abort # We want a non-zero exit code so we can fail CI pipelines, etc.
        end
      end
    end

    desc "console", "Interactive project shell"
    def console
      initialize!
      # Start's an interactive console.
      REPL.new(context: configuration).start
    end

    desc "new PATH", "Create new project at PATH"
    def new(target)
      # Peg the generated site to roughly the released version.
      *segments, _ = Gem::Version.new(Sitepress::VERSION).segments
      @target_sitepress_version = segments.join(".")

      inside target do
        directory self.class.source_root, "."
        run "bundle install"
      end
    end

    desc "version", "Show version"
    def version
      say Sitepress::VERSION
    end

    private
    def configuration
      Sitepress.configuration
    end

    # Compile assets using the available asset pipeline
    def compile_assets(target_path:)
      target_path = Pathname.new(target_path)

      if defined?(Sprockets::Railtie) && rails.respond_to?(:assets) && rails.assets
        compile_assets_with_sprockets(target_path)
      elsif defined?(Propshaft::Railtie)
        compile_assets_with_propshaft(target_path)
      else
        compile_assets_with_copy(target_path)
      end
    end

    # Compile assets using Sprockets
    def compile_assets_with_sprockets(target_path)
      logger.info "  Using Sprockets asset pipeline"
      manifest = Sprockets::Manifest.new(rails.assets, target_path.join("assets/manifest.json"))
      manifest.environment.logger = logger
      manifest.compile(precompile_assets)
    end

    # Compile assets using Propshaft
    def compile_assets_with_propshaft(target_path)
      logger.info "  Using Propshaft asset pipeline"
      assets_target = target_path.join("assets")
      FileUtils.mkdir_p(assets_target)

      # Use Propshaft's assembly to compile assets
      if rails.respond_to?(:assets) && rails.assets.respond_to?(:output_path)
        # Propshaft compiles to public/assets by default, copy from there
        propshaft_output = rails.assets.output_path
        if propshaft_output&.exist?
          FileUtils.cp_r(Dir[propshaft_output.join("*")], assets_target)
        else
          # Fallback: copy assets directly from source paths
          copy_assets_from_paths(assets_target)
        end
      else
        copy_assets_from_paths(assets_target)
      end
    end

    # Compile assets by simply copying them (no-build approach)
    def compile_assets_with_copy(target_path)
      logger.info "  No asset pipeline detected, copying assets directly"
      assets_target = target_path.join("assets")
      copy_assets_from_paths(assets_target)
    end

    # Copy assets from configured asset paths
    def copy_assets_from_paths(assets_target)
      FileUtils.mkdir_p(assets_target)

      # Get asset paths from the Rails application
      asset_paths = rails.paths["app/assets"].existent
      asset_paths.each do |source_path|
        source = Pathname.new(source_path)
        next unless source.exist?

        # Copy all files from this asset path
        Dir[source.join("**", "*")].each do |file|
          next if File.directory?(file)
          next if file.end_with?("manifest.js") # Skip Sprockets manifest files

          relative_path = Pathname.new(file).relative_path_from(source)
          target_file = assets_target.join(relative_path)
          FileUtils.mkdir_p(target_file.dirname)
          FileUtils.cp(file, target_file)
        end
      end
    end

    def rails
      configuration.parent_engine
    end

    def logger
      rails.config.logger
    end

    def precompile_assets
      rails.config.assets.precompile
    end

    def initialize!(&block)
      require_relative "boot"
      app.tap(&block) if block_given?
      app.initialize!
    end

    def app
      Sitepress::Server
    end
  end
end
