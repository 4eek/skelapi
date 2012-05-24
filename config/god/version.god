
%w{8000 8001}.each do |port|
  God.watch do |w|

    w.group = "version"
    w.name = "#{w.group}-#{port}"
    w.dir = "#{API_ROOT}"
    w.log = "#{API_ROOT}/log/#{w.group}-#{port}.log"
    w.interval = 30.seconds # default

    w.start = "bundle exec ruby api/#{w.group}.rb -sv -p #{port} -c \"./config/api.rb\" -e #{API_ENV}"

    w.start_grace = 10.seconds
    w.restart_grace = 10.seconds

    # User under which to run the process
    # w.uid = 'ubuntu'
    # w.gid = 'ubuntu'

    # Conditions under which to start the process
    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
        # c.notify = {:contacts => ['admins', 'imb_team'], :priority => 1, :category => w.group}
      end
    end

    # Conditions under which to restart the process
    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.above = 300.megabytes
        c.times = [3, 5] # 3 out of 5 intervals
        # c.notify = {:contacts => ['admins', 'imb_team'], :priority => 1, :category => w.group}
      end

      restart.condition(:cpu_usage) do |c|
        c.above = 50.percent
        c.times = 5
        # c.notify = {:contacts => ['admins', 'imb_team'], :priority => 1, :category => w.group}
      end
    end

    # lifecycle
    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :restart]
        c.times = 5
        c.within = 5.minute
        c.transition = :unmonitored
        c.retry_in = 10.minutes
        c.retry_times = 5
        c.retry_within = 2.hours
        # c.notify = {:contacts => ['admins', 'imb_team'], :priority => 1, :category => CATEGORY}
      end
    end

  end
end
