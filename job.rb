# frozen_string_literal: true

class Job
    def self.id
        raise NotImplementedError, "id method must be implemented"
    end

    def schedule
        raise NotImplementedError, "schedule method must be implemented"
    end

    def execute
        raise NotImplementedError, "execute method must be implemented"
    end
end
