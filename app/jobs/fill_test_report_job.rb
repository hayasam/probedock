# Copyright (c) 2012-2014 Lotaris SA
#
# This file is part of ROX Center.
#
# ROX Center is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ROX Center is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ROX Center.  If not, see <http://www.gnu.org/licenses/>.
require 'resque/plugins/workers/lock'

class FillTestReportJob
  extend Resque::Plugins::Workers::Lock

  @queue = :reports

  def self.perform test_report_id, test_payload_id

    report = TestReport.includes(:results).find test_report_id
    payload = TestPayload.includes(:results).find test_payload_id

    TestReport.transaction do
      report.results |= payload.results
    end
  end

  # resque-workers-lock: lock workers to prevent concurrency
  def self.lock_workers test_report_id, *args
    "#{name}:#{test_report_id}"
  end
end