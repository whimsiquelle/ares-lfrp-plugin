# aresmush/plugins/lfrp/web/lfrp_stop_request_handler.rb

module AresMUSH
  module Lfrp
    class LfrpStopRequestHandler

      def handle(request)
        error = Website.check_login(request)
        return error if error

        enactor = request.enactor
        return { error: t('webportal.login_required') } if !enactor

        Lfrp.stop(enactor)

        {
          success: true,
          message: "You are no longer looking for RP.",
          lfrp: Lfrp.web_sidebar_data(enactor)
        }
      rescue Exception => ex
        Global.logger.error "Unable to stop LFRP from web: #{ex}"
        { error: "Unable to clear your looking-for-RP status." }
      end

    end
  end
end
