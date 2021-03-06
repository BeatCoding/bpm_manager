require "rest-client"
require "json"
require "ostruct"

module BpmManager
  module RedHat
    # Gets all server deployments
    def self.deployments()
      JSON.parse(BpmManager.server['/deployment'].get)
    end
    
    # Gets all available processes
    def self.processes()
      JSON.parse(BpmManager.server['/deployment/processes'].get)['processDefinitionList']
    end

    # Creates a new Process
    def self.create_process(deployment_id, process_definition_id, opts = {})
      BpmManager.server['/runtime/' + deployment_id.to_s + '/process/' + process_definition_id.to_s + '/start'].post(opts)
    end
    
    # Gets all Process Instances
    def self.process_instances
      JSON.parse(BpmManager.server['/history/instances'].get)
    end
    
    # Gets all the runtime processes with query options
    def self.processes_query_with_opts(opts = {})
      JSON.parse(BpmManager.server['/query/runtime/process/' + (opts.empty? ? '' : '?' + opts.map{|k,v| (v.class == Array) ? v.map{|e| k.to_s + '=' + e.to_s}.join('&') : k.to_s + '=' + v.to_s}.join('&'))].get)['processInstanceInfoList']
    end
    
    # Gets a Process Instance
    def self.process_instance(process_instance_id)
      begin
        JSON.parse(BpmManager.server['/history/instance/' + process_instance_id.to_s].get)
      rescue Exception
        {}   # returns nil string in case of error
      end
    end

    # Gets a Process Instance Nodes
    def self.process_instance_nodes(process_instance_id)
      begin
        JSON.parse(BpmManager.server['/history/instance/' + process_instance_id.to_s + '/node'].get)['historyLogList']
      rescue
        {}   # returns nil string in case of error
      end
    end
    
    # Gets a Process Instance Variables
    def self.process_instance_variables(process_instance_id)
      begin
        result = Hash.new
        JSON.parse(BpmManager.server['/history/instance/' + process_instance_id.to_s + '/variable'].get)['historyLogList'].each{|e| result[e.first.second['variable-id']] = e.first.second['value']}
        
        return result
      rescue
        return {}   # same result as not found record in jbpm
      end
    end
    
    # Gets the Process image as SVG    
    def self.process_image(deployment_id, process_definition_id, process_id = '')
      begin
        BpmManager.server['/runtime/' + deployment_id.to_s + '/process/' + process_definition_id.to_s + '/image' + ((process_id.to_s.nil? || process_id.to_s.empty?) ? '' : '/' + process_id.to_s)].get
      rescue
        return ''   # returns an empty string in case of error
      end
    end
    
    # Gets all tasks, optionally you could specify an user id
    def self.tasks(user_id = '')
      self.structure_task_data(JSON.parse(BpmManager.server['/task/query?taskOwner=' + user_id].get))
    end
    
    # Gets all tasks with options
    def self.tasks_with_opts(opts = {})
      self.structure_task_data(JSON.parse(BpmManager.server['/task/query' + (opts.empty? ? '' : '?' + opts.map{|k,v| (v.class == Array) ? v.map{|e| k.to_s + '=' + e.to_s}.join('&') : k.to_s + '=' + v.to_s}.join('&'))].get))
    end
    
    # Assigns a Task for an User
    def self.assign_task(task_id, user_id)
      BpmManager.server['/task/' + task_id.to_s + '/delegate'].post(:targetEntityId => user_id.to_s)
    end

    # Gets all the information for a Task ID
    def self.task_query(task_id)
      begin
        JSON.parse(BpmManager.server['/task/' + task_id.to_s].get)
      rescue
        {}   # returns nil string in case of error
      end
    end
    
    # Gets all the runtime Tasks with query options
    def self.tasks_query_with_opts(opts = {})
      structure_task_query_data(JSON.parse(BpmManager.server['/query/runtime/task/' + (opts.empty? ? '' : '?' + opts.map{|k,v| (v.class == Array) ? v.map{|e| k.to_s + '=' + e.to_s}.join('&') : k.to_s + '=' + v.to_s}.join('&'))].get))
    end
  
    # Starts a Task
    def self.start_task(task_id)
      BpmManager.server['/task/' + task_id.to_s + '/start'].post({})
    end
    
    # Releases a Task
    def self.release_task(task_id)
      BpmManager.server['/task/' + task_id.to_s + '/release'].post({})
    end
    
    # Stops a Task
    def self.stop_task(task_id)
      BpmManager.server['/task/' + task_id.to_s + '/stop'].post({})
    end
    
    # Suspends a Task
    def self.suspend_task(task_id)
      BpmManager.server['/task/' + task_id.to_s + '/suspend'].post({})
    end
    
    # Resumes a Task
    def self.resume_task(task_id)
      BpmManager.server['/task/' + task_id.to_s + '/resumes'].post({})
    end
    
    # Skips a Task
    def self.skip_task(task_id)
      BpmManager.server['/task/' + task_id.to_s + '/skip'].post({})
    end
    
    # Completes a Task
    def self.complete_task(task_id, opts = {})
      BpmManager.server['/task/' + task_id.to_s + '/complete'].post(opts)
    end
    
    # Completes a Task as Administrator
    def self.complete_task_as_admin(task_id, opts = {})
      self.release_task(task_id)
      self.start_task(task_id)
      BpmManager.server['/task/' + task_id.to_s + '/complete'].post(opts)
    end
    
    # Fails a Task
    def self.fail_task(task_id)
      BpmManager.server['/task/' + task_id.to_s + '/fail'].post({})
    end
    
    # Exits a Task
    def self.exit_task(task_id)
      BpmManager.server['/task/' + task_id.to_s + '/exit'].post({})
    end
    
    # Gets the Process History
    def self.get_history(process_definition_id = "")
      if process_definition_id.empty?
        JSON.parse(BpmManager.server['/history/instances'].get)
      else
        JSON.parse(BpmManager.server['/history/process/' + process_definition_id.to_s].get)
      end
    end
    
    # Clears all the History --WARNING: Destructive action!--
    def self.clear_all_history()
      BpmManager.server['/history/clear'].post({})
    end

    # Gets the SLA for a Process Instance
    def self.get_process_sla(process_instance_id, process_sla_hours = 0, warning_offset_percent = 20)
      my_process = self.process_instance(process_instance_id)
      
      
      unless my_process.nil?
        sla = OpenStruct.new(:process => OpenStruct.new)
        start_time = Time.at(my_process['start']/1000)
        end_time = my_process['end'].nil? ? Time.now : Time.at(my_process['end']/1000)
        
        # Calculates the process sla
        sla.process.status = calculate_sla(start_time, end_time, process_sla_hours, warning_offset_percent)
        sla.process.status_name = (calculate_sla(start_time, end_time, process_sla_hours, warning_offset_percent) == 0) ? 'ok' : (calculate_sla(start_time, end_time, process_sla_hours, warning_offset_percent) == 1 ? 'warning' : 'due')
        sla.process.percentages = calculate_sla_percent(start_time, end_time, process_sla_hours, warning_offset_percent)
      end
      
      return sla
    end
    
    # Gets the SLA for a Task Instance
    def self.get_task_sla(task_instance_id, process_sla_hours = 0, task_sla_hours = 0, warning_offset_percent = 20)
      my_task = self.tasks_with_opts('taskId' => task_instance_id).first
      
      unless my_task.nil?
        sla = OpenStruct.new(:task => OpenStruct.new, :process => OpenStruct.new)
        
        # Calculates the process sla
        sla.process.status = calculate_sla(my_task.process.start_on, my_task.process.end_on, process_sla_hours, warning_offset_percent)
        sla.process.status_name = (calculate_sla(my_task.process.start_on, my_task.process.end_on, process_sla_hours, warning_offset_percent) == 0) ? 'ok' : (calculate_sla(my_task.process.start_on, my_task.process.end_on, process_sla_hours, warning_offset_percent) == 1 ? 'warning' : 'due')
        sla.process.percentages = calculate_sla_percent(my_task.process.start_on, my_task.process.end_on, process_sla_hours, warning_offset_percent)
        
        # Calculates the task sla
        sla.task.status = calculate_sla(my_task.created_on, nil, task_sla_hours, warning_offset_percent)
        sla.task.status_name = (calculate_sla(my_task.created_on, nil, task_sla_hours, warning_offset_percent) == 0) ? 'ok' : (calculate_sla(my_task.created_on, nil, task_sla_hours, warning_offset_percent) == 1 ? 'warning' : 'due')
        sla.task.percentages = calculate_sla_percent(my_task.created_on, nil, task_sla_hours, warning_offset_percent)
      end
      
      return sla
    end
    
    # Private class methods
    def self.calculate_sla(start_time, end_time = Time.now, sla_hours = 0.0, offset = 20)
      end_time  = Time.now   if end_time.nil?
      hours     = sla_hours.to_f * 3600   # Converts to seconds and calculates warning offset
      warn      = start_time.utc + hours * ((100.0 - offset) / 100)
      total     = start_time.utc + hours
      
      # Returns the status      
      end_time.utc <= warn ? 0 : ( warn < end_time.utc && end_time.utc <= total ? 1 : 2 )
    end
    private_class_method :calculate_sla
    
    def self.calculate_sla_percent(start_time, end_time = Time.now, sla_hours = 0.0, offset = 20)
      end_time    = Time.now   if end_time.nil?
      sla_hours   = sla_hours * 3600.0   # converts to seconds
      offset_pcg  = (100.0 - offset) / 100.0
      percent     = OpenStruct.new
      
      unless sla_hours < 0.01 # it's near zero or negative
        if end_time.utc > (start_time.utc + sla_hours) # Ruby Red
          total = (end_time.utc - start_time.utc).to_f
          percent.green  = (sla_hours * offset_pcg / total * 100).round(2)
          percent.yellow = ((sla_hours / total * 100) - percent.green).round(2)
          percent.red    = (100 - percent.yellow - percent.green).round(2)
        else   # Still Green
          total = sla_hours
          percent.green  = end_time.utc <= start_time.utc + total * offset_pcg ? ((100-offset) - (((start_time.utc + total * offset_pcg) - end_time.utc) * 100).to_f / (total * offset_pcg).to_f).round(2) : 100 - offset
          percent.yellow = end_time.utc <= start_time.utc + total * offset_pcg ? 0.0 : (offset - (start_time.utc + total - end_time.utc).to_f * 100 / (total * offset_pcg).to_f).round(2)
          percent.red    = 0.0
        end
        
        # Safe to 0.0
        percent.green  = percent.green < 0.0 ? 0.0 : percent.green
        percent.yellow = percent.yellow < 0.0 ? 0.0 : percent.yellow
        percent.red    = percent.red < 0.0 ? 0.0 : percent.red
      else
        percent.green  = 100.0
        percent.yellow = 0.0
        percent.red    = 0.0
      end
      
      return percent
    end
    private_class_method :calculate_sla_percent
    
    private
      def self.structure_task_data(input)
        tasks = []
        
        unless input['taskSummaryList'].nil? || input['taskSummaryList'].empty?
          input['taskSummaryList'].each do |task|
            task_query = self.task_query(task['id'])
            my_task                     = OpenStruct.new
            my_task.id                  = task['id']
            my_task.name                = task['name']
            my_task.subject             = task['subject']
            my_task.description         = task['description']
            my_task.status              = task['status']
            my_task.priority            = task['priority']
            my_task.skippable           = task['skippable']
            my_task.created_on          = Time.at(task['created-on']/1000)
            my_task.active_on           = Time.at(task['activation-time']/1000)
            my_task.process_instance_id = task['process-instance-id']
            my_task.process_id          = task['process-id']
            my_task.process_session_id  = task['process-session-id']
            my_task.deployment_id       = task['deployment-id']
            my_task.quick_task_summary  = task['quick-task-summary']
            my_task.parent_id           = task['parent_id']
            my_task.form_name           = task_query['form-name']
            my_task.creator             = task_query['taskData']['created-by']
            my_task.owner               = task['actual-owner']
            my_task.data                = task
            
            my_task.process               = OpenStruct.new
            my_task.process.data          = self.process_instance(task['process-instance-id'])
            my_task.process.deployment_id = task['deployment-id']
            my_task.process.id            = my_task.process.data['process-id']
            my_task.process.instance_id   = my_task.process.data['process-instance-id']
            my_task.process.start_on      = my_task.process.data['start'].nil? ? Time.now : Time.at(my_task.process.data['start']/1000)
            my_task.process.end_on        = my_task.process.data['end'].nil? ? nil : Time.at(my_task.process.data['end']/1000)
            my_task.process.name          = my_task.process.data['process-name']
            my_task.process.version       = my_task.process.data['process-version']
            my_task.process.creator       = my_task.process.data['identity']
            my_task.process.variables     = self.process_instance_variables(my_task.process.instance_id)
            tasks << my_task
          end
        end
        
        return tasks
      end
      
      def self.structure_task_query_data(input)
        tasks = []
        
        unless input['taskInfoList'].nil? || input['taskInfoList'].empty?
          input['taskInfoList'].each do |tasks_array|
            task        = tasks_array['taskSummaries'].max_by{|e| e['created-on']}  # Selects only the last active task
            task_query  = self.task_query(task['id'])
            my_task                     = OpenStruct.new
            my_task.id                  = task['id']
            my_task.name                = task['name']
            my_task.subject             = task['subject']
            my_task.description         = task['description']
            my_task.status              = task['status']
            my_task.priority            = task['priority']
            my_task.skippable           = task['skippable']
            my_task.created_on          = Time.at(task['created-on']/1000)
            my_task.active_on           = Time.at(task['activation-time']/1000)
            my_task.process_instance_id = task['process-instance-id']
            my_task.process_id          = task['process-id']
            my_task.process_session_id  = task['process-session-id']
            my_task.deployment_id       = task['deployment-id']
            my_task.quick_task_summary  = task['quick-task-summary']
            my_task.parent_id           = task['parent_id']
            my_task.form_name           = task_query['form-name']
            my_task.creator             = task_query['taskData']['created-by']
            my_task.owner               = task['actual-owner']
            my_task.data                = task
            
            my_task.process               = OpenStruct.new
            my_task.process.data          = self.process_instance(task['process-instance-id'])
            my_task.process.deployment_id = task['deployment-id']
            my_task.process.id            = my_task.process.data['process-id']
            my_task.process.instance_id   = my_task.process.data['process-instance-id']
            my_task.process.start_on      = my_task.process.data['start'].nil? ? Time.now : Time.at(my_task.process.data['start']/1000)
            my_task.process.end_on        = my_task.process.data['end'].nil? ? nil : Time.at(my_task.process.data['end']/1000)
            my_task.process.name          = my_task.process.data['process-name']
            my_task.process.version       = my_task.process.data['process-version']
            my_task.process.creator       = my_task.process.data['identity']
            my_task.process.variables     = self.process_instance_variables(my_task.process.instance_id)
            tasks << my_task
          end
        end
        
        return tasks
      end
  end
end