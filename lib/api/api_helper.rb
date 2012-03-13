module Api
  module ApiHelper

    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
    end

    module InstanceMethods
      def logger
        Api.logger
      end

      def respond_ok(headers={}, body=nil)
        [200, headers, [body.to_s]]
      end

      def respond_bad_request(headers={}, body=nil)
        [400, headers, [body.to_s]]
      end

      def respond_bad_gateway(headers={}, body=nil)
        [502, headers, [body.to_s]]
      end

      def ip(env)
        if addr = env['HTTP_X_FORWARDED_FOR']
          (addr.split(',').grep(/\d\./).first || env['REMOTE_ADDR']).to_s.strip
        else
          env['REMOTE_ADDR']
        end
      end

      def record(process_time, resp, env)
        env.trace('record_beg')

        EM.next_tick do
          doc = {
            request: {
              http_method: env[Goliath::Request::REQUEST_METHOD],
              path: env[Goliath::Request::REQUEST_PATH],
              headers: env['client_headers'],
              params: env.params
            },
              response: {
                status: resp[0],
                length: resp[2].length,
                headers: resp[1],
                body: resp[2]
            },
              ip: ip(env),
              remote_addr: env['REMOTE_ADDR'],
              process_time: process_time,
              date: Time.now.to_i
          }

          if env[Goliath::Request::RACK_INPUT]
            doc[:request][:body] = env[Goliath::Request::RACK_INPUT].read
          end

          env.db.collection(:http_logs).insert(doc)
        end
        env.trace('record_end')
      end

    end

  end
end
