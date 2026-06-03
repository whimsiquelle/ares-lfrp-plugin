$:.unshift File.dirname(__FILE__)
require "time"

module AresMUSH
  module Lfrp

    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.shortcuts
      Global.read_config("lfrp", "shortcuts")
    end

    def self.get_cmd_handler(client, cmd, enactor)
      case cmd.root
      when "lfrp"
        if cmd.switch_is?("stop")
          return LfrpStopCmd
        elsif cmd.switch_is?("list")
          return LfrpListCmd
        else
          return LfrpSetCmd
        end
      end

      nil
    end

    def self.get_event_handler(event_name)
      nil
    end

    def self.get_web_request_handler(request)
      case request.cmd
      when "lfrpStart"
        return LfrpStartRequestHandler
      when "lfrpStop"
        return LfrpStopRequestHandler
      when "lfrpList"
        return LfrpListRequestHandler
      end

      nil
    end

    def self.config_int(name, fallback)
      value = Global.read_config("lfrp", name)
      value = value.to_i

      return fallback if value <= 0

      value
    rescue Exception => ex
      Global.logger.warn "Unable to read LFRP config #{name}: #{ex}"
      fallback
    end

    def self.default_hours
      Lfrp.config_int("default_hours", 6)
    end

    def self.max_hours
      Lfrp.config_int("max_hours", 12)
    end

    def self.can_use_lfrp?(char)
      return false if !char

      char.is_approved?
    rescue Exception => ex
      Global.logger.warn "Unable to check LFRP permission for #{char ? char.name : 'unknown'}: #{ex}"
      false
    end

    def self.normalize_scene_type(value)
      case value.to_s.downcase
      when "txt", "text"
        "txt"
      when "live", "live_only"
        "live"
      when "async", "async_only"
        "async"
      else
        "any"
      end
    end

    def self.scene_type_for_entry(entry)
      return "any" if !entry

      Lfrp.normalize_scene_type(entry.scene_type)
    rescue Exception => ex
      Global.logger.warn "Unable to determine LFRP scene type: #{ex}"
      "any"
    end

    def self.scene_type_label(scene_type)
      case Lfrp.normalize_scene_type(scene_type)
      when "txt"
        "TXT Only"
      when "live"
        "Live Only"
      when "async"
        "Async Only"
      else
        "Any Scene"
      end
    end

    def self.scene_type_sort_order(scene_type)
      case Lfrp.normalize_scene_type(scene_type)
      when "any"
        0
      when "txt"
        1
      when "live"
        2
      when "async"
        3
      else
        4
      end
    end

    def self.find_entry(char)
      return nil if !char

      LfrpEntry.find(character_id: char.id).first
    end

    def self.active?(entry)
      return false if !entry
      return false if entry.expires.blank?

      Time.parse(entry.expires) > Time.now
    rescue Exception => ex
      Global.logger.warn "Unable to check LFRP expiration: #{ex}"
      false
    end

    def self.active_entries
      LfrpEntry.all.select { |entry| Lfrp.active?(entry) }
    rescue Exception => ex
      Global.logger.warn "Unable to build active LFRP entries: #{ex}"
      []
    end
    def self.start(char, hours = nil, scene_type = "any")
      Lfrp.cleanup_expired

      return if !char
      return if !Lfrp.can_use_lfrp?(char)

      scene_type = Lfrp.normalize_scene_type(scene_type)

      hours = hours.to_i
      hours = Lfrp.default_hours if hours <= 0
      hours = [[hours, 1].max, Lfrp.max_hours].min

      entry = Lfrp.find_entry(char)
      was_active = Lfrp.active?(entry)
      previous_scene_type = was_active ? Lfrp.scene_type_for_entry(entry) : nil

      expires = Time.now + (hours * 3600)

      data = {
        character: char,
        expires: expires.iso8601,
        scene_type: scene_type
      }

      if entry
        entry.update(data)
      else
        LfrpEntry.create(data)
      end

      if !was_active
        case scene_type
        when "txt"
          Lfrp.announce_to_rp_requests("LFRP: #{char.name} is looking for a TXT scene!")
        when "live"
          Lfrp.announce_to_rp_requests("LFRP: #{char.name} is looking for a live scene!")
        when "async"
          Lfrp.announce_to_rp_requests("LFRP: #{char.name} is looking for an async scene!")
        else
          Lfrp.announce_to_rp_requests("LFRP: #{char.name} is looking for RP!")
        end
      elsif previous_scene_type != scene_type
        previous_label = Lfrp.scene_type_label(previous_scene_type)
        new_label = Lfrp.scene_type_label(scene_type)

        Lfrp.announce_to_rp_requests(
          "LFRP: #{char.name} changed their scene preference from #{previous_label} to #{new_label}."
        )
      end
    end

    def self.stop(char)
      entry = Lfrp.find_entry(char)
      return if !entry

      was_active = Lfrp.active?(entry)
      entry.delete

      if was_active
        Lfrp.announce_to_rp_requests("LFRP: #{char.name} has stopped looking for RP.")
      end
    end

    def self.expires_in_words(entry)
      return "Unknown" if !entry || entry.expires.blank?

      seconds = Time.parse(entry.expires) - Time.now
      return "Expired" if seconds <= 0

      minutes = (seconds / 60).ceil

      if minutes < 60
        "#{minutes} min"
      else
        hours = minutes / 60
        mins = minutes % 60

        if mins == 0
          "#{hours} hr"
        else
          "#{hours} hr #{mins} min"
        end
      end
    rescue Exception => ex
      Global.logger.warn "Unable to format LFRP expiration: #{ex}"
      "Unknown"
    end

    def self.web_sidebar_data(viewer = nil)
      Lfrp.active_entries.map do |entry|
        char = entry.character
        next if !char

        scene_type = Lfrp.scene_type_for_entry(entry)
        online = Login.is_online_or_on_web?(char)

        icon = ""
        status = ""

        begin
          icon_value = Website.icon_for_char(char)
          icon = icon_value ? icon_value.to_s : ""
        rescue Exception => ex
          Global.logger.warn "Unable to get LFRP icon for #{char.name}: #{ex}"
        end

        begin
          status_value = Website.activity_status(char)
          status = status_value ? status_value.to_s : ""
        rescue Exception => ex
          Global.logger.warn "Unable to get LFRP activity status for #{char.name}: #{ex}"
        end

        {
          char: {
            name: char.name.to_s,
            icon: icon,
            status: status
          },
          name: char.name.to_s,
          scene_type: scene_type,
          scene_type_label: Lfrp.scene_type_label(scene_type),
          show_scene_type_badge: scene_type != "any",
          expires: Lfrp.expires_in_words(entry).to_s,
          online: online ? true : false
        }
      end.compact.sort_by do |entry|
        [
          Lfrp.scene_type_sort_order(entry[:scene_type]),
          entry[:name]
        ]
      end
    rescue Exception => ex
      Global.logger.warn "Unable to build LFRP sidebar data: #{ex.class} - #{ex.message}"
      []
    end

    def self.announce_channel_name
      channel = Global.read_config("lfrp", "announce_channel")
      channel.blank? ? "RP Requests" : channel
    rescue Exception => ex
      Global.logger.warn "Unable to read LFRP announce channel config: #{ex}"
      "RP Requests"
    end

    def self.announce_to_rp_requests(message)
      channel_name = Lfrp.announce_channel_name
      channel = Channel.named(channel_name)

      if !channel
        Global.logger.warn "Unable to announce LFRP update. Channel not found: #{channel_name}"
        return
      end

      enactor = Game.master.system_character

      Channels.emit_to_channel(channel, message, enactor, "")
      Channels.notify_discord_webhook(channel, message, enactor)
    rescue Exception => ex
      Global.logger.warn "Unable to announce LFRP update: #{ex}"
    end

    def self.cleanup_expired
      LfrpEntry.all.each do |entry|
        entry.delete if !Lfrp.active?(entry)
      end
    rescue Exception => ex
      Global.logger.warn "Unable to clean up expired LFRP entries: #{ex}"
    end

  end
end
