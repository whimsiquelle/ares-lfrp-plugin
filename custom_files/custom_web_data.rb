module AresMUSH
  module Website
    # Gets custom fields for the sidebar.
    #
    # @param [Character] viewer - The character viewing the sidebar. May be nil if someone is viewing
    #    the web portal without being logged in.
    #
    # @return [Hash] - A hash containing custom fields and values.
    #    Ansi or markdown text strings must be formatted for display.
    #
    # NOTE: The sidebar is called frequently because it appears on every page.
    # Keep this data lightweight.
    def self.custom_sidebar_data(viewer)
      return {
        lfrp: Lfrp.web_sidebar_data(viewer),
        lfrp_can_use: Lfrp.can_use_lfrp?(viewer),
        lfrp_active: Lfrp.active?(Lfrp.find_entry(viewer)),
        lfrp_refresh_seconds: Lfrp.refresh_seconds
      }
    end
  end
end
