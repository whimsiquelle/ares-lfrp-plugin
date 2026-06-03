module AresMUSH
  module Lfrp
    class LfrpStopCmd
      include CommandHandler

      def handle
        Lfrp.stop(enactor)
        client.emit_success "You are no longer marked as looking for RP."
      end
    end
  end
end
