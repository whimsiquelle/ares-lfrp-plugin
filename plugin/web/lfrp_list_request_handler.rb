# aresmush/plugins/lfrp/web/lfrp_list_request_handler.rb

module AresMUSH
  module Lfrp
    class LfrpListRequestHandler
      def handle(request)
        enactor = request.enactor

        {
          lfrp: Lfrp.web_sidebar_data(enactor),
          lfrp_can_use: Lfrp.can_use_lfrp?(enactor),
          lfrp_active: Lfrp.active?(Lfrp.find_entry(enactor))
        }
      end
    end
  end
end
