# Copyright (c) 2015 ProbeDock
# Copyright (c) 2012-2014 Lotaris SA
#
# This file is part of ProbeDock.
#
# ProbeDock is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ProbeDock is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ProbeDock.  If not, see <http://www.gnu.org/licenses/>.
class TestResultPolicy < ApplicationPolicy
  def index?
    admin? || public?(organization) || member_of?(organization)
  end

  class Serializer < Serializer
    include ScmHelper

    def to_builder(options = {})
      payload = options[:payloads].find{ |p| p.id == record.test_payload_id } if options[:payloads]

      unless payload
        raise "Expected options[:payloads] to contain test payload with ID #{record.test_payload_id}"
      end

      source_url = build_source_url(record, record.project_version.project, payload)

      Jbuilder.new do |json|
        json.id record.id
        json.name record.name
        json.testId record.test.api_id if record.test.present?
        json.passed record.passed
        json.active record.active
        json.message record.message
        json.duration record.duration
        json.key record.key.key if record.key.present? && record.payload_properties_set?(:key)
        json.newTest record.new_test
        json.category record.category.name if record.category.present?
        json.tags record.tags.collect(&:name)
        json.tickets record.tickets.collect(&:name)
        json.customData record.custom_values
        json.runner serialize(record.runner, link: true)
        json.project serialize(record.project_version.project, link: true)
        json.projectVersion record.project_version.name
        json.runAt record.run_at.iso8601(3)
        json.sourceUrl source_url if source_url
        if options[:with_scm]
          json.scm build_scm_data(payload)
        end
      end
    end
  end
end
