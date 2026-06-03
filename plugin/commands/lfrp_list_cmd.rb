# aresmush/plugins/lfrp/commands/lfrp_list_cmd.rb

module AresMUSH
  module Lfrp
    class LfrpListCmd
      include CommandHandler

      def handle
        Lfrp.cleanup_expired

        entries = Lfrp.active_entries
          .select { |entry| entry.character }
          .sort_by do |entry|
            [
              Lfrp.scene_type_sort_order(Lfrp.scene_type_for_entry(entry)),
              entry.character.name
            ]
          end

        lines = []
        lines << "%xh%xrLooking for RP%xn"
        lines << ""

        if entries.empty?
          lines << "No one is currently marked as looking for RP."
          client.emit_ooc lines.join("%R")
          return
        end

        header = "%-25s %-14s %-12s %-20s" % [ "Character", "Type", "Status", "Expires" ]
        divider = "-" * 76

        lines << "%xc#{header}%xn"
        lines << "%xc#{divider}%xn"

        entries.each do |entry|
          char = entry.character
          scene_type = Lfrp.scene_type_label(Lfrp.scene_type_for_entry(entry))
          status = Login.is_online_or_on_web?(char) ? "Online" : "Offline"
          expires = Lfrp.expires_in_words(entry)

          row = "%-25s %-14s %-12s %-20s" % [ char.name, scene_type, status, expires ]
          lines << row
        end

        client.emit_ooc lines.join("%R")
      end
    end
  end
end
