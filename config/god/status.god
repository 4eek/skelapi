
%w{9000 9001}.each do |port|
  God.watch do |w|

    w.group = "status"
    w.name = "#{w.group}-#{port}"
    w.dir = "#{API_ROOT}"
    w.log = "#{API_ROOT}/log/#{w.group}-#{port}.log"
    w.interval = 30.seconds # default

    w.stop_signal = 'QUIT'
    w.stop_timeout = 20.seconds

    w.start = "bundle exec ruby api/#{w.group}.rb -sv -p #{port} -c \"./config/api.rb\" -e #{API_ENV}"

    w.start_grace = 10.seconds
    w.restart_grace = 10.seconds

    # User under which to run the process
    # w.uid = 'ubuntu'
    # w.gid = 'ubuntu'

    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end

    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.notify = {:contacts => ['admins', 'imb_team'], :priority => 1, :category => w.group}
      end

      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_exits) do |c|
        c.notify = {:contacts => ['admins', 'imb_team'], :priority => 1, :category => w.group}
      end
    end

    # restart if memory or cpu is too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.interval = 20
        c.above = 50.megabytes
        c.times = [3, 5]
        c.notify = {:contacts => ['admins', 'imb_team'], :priority => 1, :category => w.group}
      end

      on.condition(:cpu_usage) do |c|
        c.interval = 10
        c.above = 10.percent
        c.times = [3, 5]
        c.notify = {:contacts => ['admins', 'imb_team'], :priority => 1, :category => w.group}
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
        c.notify = {:contacts => ['admins', 'imb_team'], :priority => 1, :category => w.group}
      end
    end
  end

end
