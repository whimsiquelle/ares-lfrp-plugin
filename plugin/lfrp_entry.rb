module AresMUSH
  class LfrpEntry < Ohm::Model
    include ObjectModel

    reference :character, "AresMUSH::Character"

    attribute :scene_type
    attribute :expires

    index :character
  end
end
