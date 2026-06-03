# aresmush/plugins/lfrp/web/lfrp_start_request_handler.rb

module AresMUSH
  module Lfrp
    class LfrpStartRequestHandler

      def handle(request)
        error = Website.check_login(request)
        return error if error

        enactor = request.enactor
        return { error: t('webportal.login_required') } if !enactor

        hours = request.args['hours']
        scene_type = request.args['scene_type']

        scene_type = Lfrp.normalize_scene_type(scene_type)

        Lfrp.start(enactor, hours, scene_type)

        {
          success: true,
          message: "You are now looking for RP: #{Lfrp.scene_type_label(scene_type)}.",
          lfrp: Lfrp.web_sidebar_data(enactor)
        }
      rescue Exception => ex
        Global.logger.error "Unable to start LFRP from web: #{ex}"
        { error: "Unable to mark you as looking for RP." }
      end

    end
  end
end
