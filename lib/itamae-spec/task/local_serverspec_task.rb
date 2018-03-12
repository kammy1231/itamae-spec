require 'itamae'
require 'itamae-spec/task/base_task'

module ItamaeSpec
  module Task
    class LocalServerspecTask < BaseTask
      ChangeTargetError = Class.new(StandardError)
      LoadSpecError = Class.new(StandardError)

      def create_spec_command(node_name, hash)
        ENV['TARGET_HOST'] = if hash[:environments][:local_ipv4].nil?
                               hash[:environments][:hostname]
                             else
                               hash[:environments][:local_ipv4]
                             end

        ENV['NODE_FILE'] = "tmp-nodes/#{node_name}.json"
        ENV['SUDO_PASSWORD'] = hash[:environments][:sudo_password]
        ENV['LOCAL_MODE'] = 'enable local mode'

        command = 'bundle exec rspec'
      end

      def list_recipe_filepath(run_list)
        recipes = []
        run_list.each do |recipe|
          target_list = Dir.glob("cookbooks/#{recipe.keys.join}/spec/#{recipe.values.join}_spec.rb")

          raise LoadSpecError, "#{recipe.to_a.join('::')} cookbook or spec does not exist." if target_list.empty?

          target_list.each do |target|
            recipes << " #{target}"
          end
        end

        recipes
      end

      Itamae.logger.formatter.colored = true
      task = LocalServerspecTask.new

      namespace :local_spec do
        all = []

        begin
          project = { project: ARGV[1] }

          if (ARGV[0] == '-T' || ARGV[0] == '--tasks') && !project[:project].nil?
            unless Dir.exist?("nodes/#{project[:project]}")
              raise ChangeTargetError, "'#{project[:project]}' project is not exist."
            end

            File.open 'Project.json', 'w' do |f|
              f.flock File::LOCK_EX
              f.puts project.to_json
              f.flock File::LOCK_UN
            end

            Itamae.logger.color(:green) do
              Itamae.logger.info "Changed target mode '#{project[:project]}'"
            end
          end

          resp = JSON.parse(File.read('Project.json'))
          target = resp['project'] << '/**'
        rescue => e
          Itamae.logger.error e.inspect
          exit 2
        end

        Dir.glob("nodes/#{target}/*.json").each do |node_file|
          begin
            node_name = File.basename(node_file, '.json')
            node = task.load_node_attributes(node_file)
            node_short = node[:environments][:hostname].split('.')[0]
          rescue => e
            Itamae.logger.error e.inspect
            Itamae.logger.info "From node file: #{node_file}"
            exit 2
          end

          all << node_short
          desc 'Serverspec to all nodes'
          task 'all' => all

          desc "Serverspec to #{node_name}"
          task node_short do
            Itamae.logger.color(:cyan) do
              Itamae.logger.info "Start local_serverspec_task to #{node[:environments][:hostname]}"
            end

            begin
              run_list = task.load_run_list(node_file)
              environments = task.load_environments(node)
              recipe_attributes_list = task.load_recipe_attributes(run_list)

              merged_recipe = task.merge_attributes(recipe_attributes_list)
              merged_environments = task.merge_attributes(merged_recipe, environments)
              attributes = task.merge_attributes(merged_environments, node)
              task.create_tmp_nodes(node_name, attributes)

              command = task.create_spec_command(node_name, attributes)
              command_recipe = task.list_recipe_filepath(run_list)
              command << command_recipe.join

              task.runner_display(attributes[:run_list], run_list, command)
              st = system command
              if st
                Itamae.logger.color(:green) do
                  Itamae.logger.info 'local_serverspec_task is completed.'
                end
              else
                Itamae.logger.error 'local_serverspec_task is failed.'
                exit 1
              end
            rescue => e
              Itamae.logger.error e.inspect
              Itamae.logger.info "From node file: #{node_file}"
              exit 2
            end
          end
        end
      end
    end
  end
end
