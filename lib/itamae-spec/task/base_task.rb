require 'itamae-spec/task/base'

module ItamaeSpec
  module Task
    class BaseTask

      include Base
      extend Rake::DSL if defined? Rake::DSL

      LoadRecipeError = Class.new(StandardError)
      LoadAttributeError = Class.new(StandardError)

      def load_node_attributes(node_file)
        JSON.parse(File.read(node_file), symbolize_names: true)
      rescue JSON::ParserError
        raise LoadAttributeError, "JSON Parser Failed. - #{node_file}"
      end

      def load_run_list(node_file)
        run_list = []
        Base.get_node_recipes(node_file).each {|recipe| run_list << recipe }
        run_list.flatten
      end

      def load_environments(environments)
        JSON.parse(File.read("environments/#{environments}.json"), symbolize_names: true)
      rescue JSON::ParserError
        raise LoadAttributeError, "JSON Parser Failed. - environments/#{environments}.json"
      end

      def load_role_attributes(role)
        attributes = JSON.parse(File.read("roles/#{role}.json"), symbolize_names: true)
        attributes.delete(:run_list)
        key = attributes[role.to_sym]
        raise LoadAttributeError, 'Role attribute is not specified in :role_name' if key.nil?
        attributes
      rescue JSON::ParserError
        raise LoadAttributeError, "JSON Parser Failed. - roles/#{role}.json"
      end

      def load_recipe_attributes(run_list)
        recipe_files = run_list.map do |recipe|
          Dir.glob("cookbooks/**/#{recipe.keys.join}/attributes/#{recipe.values.join}.json")
        end.flatten

        recipe_files.map do |f|
          begin
            JSON.parse(File.read(f), symbolize_names: true)
          rescue JSON::ParserError
            raise LoadAttributeError, "JSON Parser Failed. - #{f}"
          end
        end
      end

      def merge_attributes(source, other = nil)
        if source.class == Hash
          merged = source.deep_merge(other)
        elsif source.class == Array
          if source.empty?
            merged = {}
          else
            merged = source[0]
            source.each {|s| merged.deep_merge!(s) }
          end
        end

        merged
      end

      def apply_attributes(node_file)
        node_attributes = load_node_attributes(node_file)
        environments = Base.get_environments(node_file)
        environments_attributes = load_environments(environments)
        roles = Base.get_roles(node_file)
        role_attributes_list = roles.map {|role | load_role_attributes(role) }
        run_list = load_run_list(node_file)
        recipe_attributes_list = load_recipe_attributes(run_list)

        merged_recipe = merge_attributes(recipe_attributes_list)
        merged_environments = merge_attributes(merged_recipe, environments_attributes)
        merged_role_each = merge_attributes(role_attributes_list)
        merged_role = merge_attributes(merged_environments, merged_role_each)
        attributes = merge_attributes(merged_role, node_attributes)
      end

      def create_tmp_nodes(filename, hash)
        json = hash.to_pretty_json
        Base.write_tmp_nodes(filename) {|f| f.puts json }
      end

      def create_itamae_command(node_name, hash)
        ENV['SUDO_PASSWORD'] if hash[:environments][:sudo_password]

        command = 'bundle exec itamae-spec ssh'
        command << if hash[:environments][:local_ipv4]
                     " -h #{hash[:environments][:local_ipv4]}"
                   else
                     " -h #{hash[:environments][:hostname]}"
                   end

        command << " -u #{hash[:environments][:ssh_user]}"
        command << if hash[:environments][:ssh_port]
                     " -p #{hash[:environments][:ssh_port]}"
                   else
                     ' -p 22'
                   end
        command << " -i keys/#{hash[:environments][:ssh_key]}" if hash[:environments][:ssh_key]
        command << " -j tmp-nodes/#{node_name}.json"

        hash[:environments][:shell] = ENV['shell'] if ENV['shell']
        command << if hash[:environments][:shell]
                     " --shell=#{hash[:environments][:shell]}"
                   else
                     ' --shell=bash'
                   end

        command << " --password=#{hash[:environments][:ssh_password]}" if hash[:environments][:ssh_password]
        command << ' --dry-run' if ENV['dry-run'] == 'true'
        command << ' --log-level=debug' if ENV['debug'] == 'true'
        command << ' --vagrant' if ENV['vagrant'] == 'true'
        command
      end

      def create_spec_command(node_name, hash)
        ENV['TARGET_HOST'] = if hash[:environments][:local_ipv4].nil?
                               hash[:environments][:hostname]
                             else
                               hash[:environments][:local_ipv4]
                             end

        ENV['NODE_FILE'] = "tmp-nodes/#{node_name}.json"
        ENV['SSH_PASSWORD'] = hash[:environments][:ssh_password]
        ENV['SUDO_PASSWORD'] = hash[:environments][:sudo_password]
        ENV['SSH_KEY'] = "keys/#{hash[:environments][:ssh_key]}"
        ENV['SSH_USER'] = hash[:environments][:ssh_user]
        ENV['SSH_PORT'] = hash[:environments][:ssh_port]

        command = 'bundle exec rspec'
        # ENV['vagrant'] TODO
      end

      def list_recipe_filepath(run_list)
        recipes = []
        run_list.each do |recipe|
          target_list = Dir.glob("cookbooks/**/#{recipe.keys.join}/recipes/#{recipe.values.join}.rb")

          raise LoadRecipeError, "#{recipe.to_a.join('::')} cookbook or recipe does not exist." if target_list.empty?

          target_list.each do |target|
            recipes << " #{target}"
          end
        end

        recipes
      end

      def runner_display(raw_run_list, run_list, command)
        run_list_str = run_list.map do |recipe|
          if recipe.values.join == 'default'
            recipe.keys.join
          else
            "#{recipe.keys.join}::#{recipe.values.join}"
          end
        end

        Itamae.logger.color(:green) do
          Itamae.logger.info "Run List is [#{raw_run_list.join(', ')}]"
          Itamae.logger.info "Run List expands to [#{run_list_str.join(', ')}]"
        end

        Itamae.logger.color(:white) do
          Itamae.logger.info command
        end
      end
    end
  end
end
