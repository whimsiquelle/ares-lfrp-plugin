module AresMUSH
  module Lfrp
    class LfrpSetCmd
      include CommandHandler

      attr_accessor :hours

      def parse_args
        self.hours = cmd.args ? cmd.args.to_i : nil
      end

      def handle
        if !Lfrp.can_use_lfrp?(enactor)
          client.emit_failure "You must be approved to use Looking for RP."
          return
        end

        scene_type =
          if cmd.switch_is?("txt")
            "txt"
          elsif cmd.switch_is?("live")
            "live"
          elsif cmd.switch_is?("async")
            "async"
          else
            "any"
          end

        hours = self.hours
        hours = Lfrp.default_hours if !hours || hours <= 0
        hours = [[hours, 1].max, Lfrp.max_hours].min

        Lfrp.start(enactor, hours, scene_type)

        client.emit_success "You are now looking for RP: #{Lfrp.scene_type_label(scene_type)} for #{hours} hour(s)."
      end

    end
  end
end
