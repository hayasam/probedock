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
require 'benchmark'

module TestPayloadProcessing
  class ProcessReports
    def initialize payload
      if payload.raw_reports.present?
        existing_reports = TestReport.where(uid: payload.raw_reports.collect{ |r| r['uid'] }).to_a

        payload.raw_reports.each do |raw_report|
          if existing_report = existing_reports.find{ |r| r.uid == raw_report['uid'] }
            update_report existing_report, payload
          else
            create_report payload, raw_report['uid']
          end
        end
      else
        create_report payload
      end
    end

    private

    def create_report payload, uid = nil
      report = TestReport.new(uid: uid, organization: payload.project_version.project.organization, started_at: payload.started_at, ended_at: payload.ended_at, test_payloads: [ payload ]).tap &:save_quickly!
      update_project report, payload
    end

    def update_report report, payload

      report.test_payloads << payload

      updates = {}
      updates[:started_at] = payload.started_at if payload.started_at < report.started_at
      updates[:ended_at] = payload.ended_at if payload.ended_at > report.ended_at
      report.update_attributes! updates

      update_project report, payload
    end

    def update_project report, payload
      payload.project_version.project.update_attribute :last_report_id, report.id
    end
  end
end
