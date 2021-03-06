require "rest-client"
require "json"
require "ostruct"

module BpmManager
  module Oracle
    # Gets all tasks, optionally you could specify an user id
    def self.tasks(user_id = "")
      self.structure_task_data(JSON.parse(RestClient.get(BpmManager.uri('/tasks' + (user_id.empty? ? '' : '/' + user_id)), :accept => :json)))
    end
    
    # Gets all tasks with options
    def self.tasks_with_opts(opts = {})
      self.structure_task_data(JSON.parse(RestClient.get(BpmManager.uri('/tasks' + (opts.empty? ? '' : '?' + opts.map{|k,v| k.to_s + '=' + v.to_s}.join('&'))), :accept => :json)))
    end
    
    # Gets all Process Instances
    def self.process_instances
      JSON.parse(RestClient.get(BpmManager.uri('/processes'), :accept => :json))
    end
    
    # Gets a Process Instance
    def self.process_instance(process_instance_id)
      JSON.parse(RestClient.get(BpmManager.uri('/process/' + process_instance_id.to_s), :accept => :json))
    end
    
    # Assigns a Task for an User
    def self.assign_task(task_id, user_id)
      RestClient.post(URI.encode(BpmManager.uri('/task/assign/' + task_id.to_s + '/' + user_id.to_s)), :headers => {:content_type => :json, :accept => :json})
    end
    
    # Releases a Task
    def self.release_task(task_id)
      RestClient.post(URI.encode(BpmManager.uri('/task/release/' + task_id.to_s)), :headers => {:content_type => :json, :accept => :json})
    end
    
    # Starts a Task
    # def self.start_task(task_id)
    #   RestClient.post(URI.encode(BpmManager.uri('/task/' + task_id.to_s + '/start')), :headers => {:content_type => :json, :accept => :json})
    # end
    
    # Stops a Task
    # def self.stop_task(task_id)
    #   RestClient.post(URI.encode(BpmManager.uri('/task/' + task_id.to_s + '/stop')), :headers => {:content_type => :json, :accept => :json})
    # end
    
    # Suspends a Task
    def self.suspend_task(task_id)
      RestClient.post(URI.encode(BpmManager.uri('/task/action/' + task_id.to_s + '/SYS_SUSPEND')), :headers => {:content_type => :json, :accept => :json})
    end
    
    # Resumes a Task
    def self.resume_task(task_id)
      RestClient.post(URI.encode(BpmManager.uri('/task/action' + task_id.to_s + '/SYS_RESUME')), :headers => {:content_type => :json, :accept => :json})
    end
    
    # Skips a Task
    # def self.skip_task(task_id)
    #   RestClient.post(URI.encode(BpmManager.uri('/task/' + task_id.to_s + '/skip')), :headers => {:content_type => :json, :accept => :json})
    # end
    
    # Completes a Task
    # def self.complete_task(task_id, opts = {})
    #   RestClient.post(URI.encode(BpmManager.uri('/task/' + task_id.to_s + '/complete')), :headers => {:content_type => :json, :accept => :json})
    # end
    
    # Fails a Task
    def self.fail_task(task_id)
      RestClient.post(URI.encode(BpmManager.uri('/task/action/' + task_id.to_s + '/SYS_ERROR')), :headers => {:content_type => :json, :accept => :json})
    end
    
    # Exits a Task
    # def self.exit_task(task_id)
    #   RestClient.post(URI.encode(BpmManager.uri('/task/' + task_id.to_s + '/exit')), :headers => {:content_type => :json, :accept => :json})
    # end
    
    private
      def self.structure_task_data(input)
        tasks = []
        
        unless input.nil? || input.empty?
          input.each do |task|
            my_task = OpenStruct.new
            my_task.process = OpenStruct.new
            process_info = (task['processInfo'].nil? || task['processInfo'].empty?) ? '' : JSON.parse(task['processInfo']).first
            
            my_task.id = task['number']
            my_task.process_instance_id = task['processInstanceId']
            my_task.parent_id = ''
            my_task.created_on = Time.parse(task['created_on'])
            my_task.active_on = Time.parse(task['created_on'])
            my_task.name = task['title']
            my_task.owner = task['owner']
            my_task.status = task['status']
            my_task.subject = ''
            my_task.description = ''
            my_task.data = ''
            
            my_task.process.data = process_info
            my_task.process.deployment_id = ''
            my_task.process.id = (process_info.nil? || process_info.empty?) ? '' : process_info['processId']
            
            my_task.process.instance_id = task['processInstanceId']
            my_task.process.start_on = Time.parse(task['created_on'])
            my_task.process.name = task['processName']
            my_task.process.version = (process_info.nil? || process_info.empty?) ? '' : process_info['revision']
            my_task.process.creator = task['creatorName']
            my_task.process.variables = nil # self.process_instance_variables(my_task.process.deployment_id, my_task.process.instance_id)
            tasks << my_task
          end
        end
        
        return tasks
      end
  end
end