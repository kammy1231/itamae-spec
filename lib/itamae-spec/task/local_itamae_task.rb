require 'itamae-spec/task/base_task'

module ItamaeSpec
  module Task
    class LocalItamaeTask < BaseTask
      def create_itamae_command(node_name, hash)
        command = 'bundle exec itamae-spec local'
        command << " -j tmp-nodes/#{node_name}.json"

        hash[:environments][:shell] = ENV['shell'] if ENV['shell']
        command << if hash[:environments][:shell]
                     " --shell=#{hash[:environments][:shell]}"
                   else
                     ' --shell=bash'
                   end

        command << ' --dry-run' if ENV['dry-run'] == 'true'
        command << ' --log-level=debug' if ENV['debug'] == 'true'
        command
      end

      Itamae.logger.formatter.colored = true
      task = LocalItamaeTask.new

      namespace :local_itamae do
        all = []

        Dir.glob('nodes/**/*.json').each do |node_file|
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
          desc 'Itamae local to all nodes'
          task 'all' => all

          desc "Itamae local to #{node_name}"
          task node_short do
            Itamae.logger.color(:cyan) do
              Itamae.logger.info "Start local_itamae_task to #{node[:environments][:hostname]}"
            end

            begin
              run_list = task.load_run_list(node_file)
              attributes = task.apply_attributes(node_file)
              task.create_tmp_nodes(node_name, attributes)

              command = task.create_itamae_command(node_name, attributes)
              command_recipe = task.list_recipe_filepath(run_list)
              command << command_recipe.join

              task.runner_display(attributes[:run_list], run_list, command)
              st = system command
              if st
                Itamae.logger.color(:green) do
                  Itamae.logger.info 'local_itamae_task is completed.'
                end
              else
                Itamae.logger.error 'local_itamae_task is failed.'
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
