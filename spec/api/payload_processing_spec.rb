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
require 'spec_helper'

RSpec.describe 'Payload processing' do
  include PayloadProcessingSpecHelper

  let(:organization){ create :organization }
  let!(:projects){ Array.new(2){ create :project, organization: organization } }
  let!(:user){ create :org_member, organization: organization }

  it "should process a simple payload", probedock: { key: 'rbzu' } do

    # prepare payload
    raw_payload = generate_raw_payload projects[0], results: [
      { n: 'It should work', t: %w(t1 t2) },
      { n: 'It might work', p: false, c: 'RSpec', g: %w(foo bar baz) },
      { n: 'It should also work', c: nil, g: %w(baz qux), t: %w(t2) }
    ]

    store_preaction_state

    # publish payload
    with_resque do
      api_post '/api/publish', raw_payload.to_json, user: user
      expect_http_status_code 202
      check_json_payload_response @response_body, projects[0], user, raw_payload
    end

    # check database changes
    expect_changes test_payloads: 1, test_reports: 1, test_results: 3, project_versions: 1, project_tests: 3, test_descriptions: 3, categories: 1, tags: 4, tickets: 2

    # check payload & report
    payload = check_json_payload @response_body, raw_payload, testsCount: 3, newTestsCount: 3
    check_report payload, organization: organization

    # check project & version
    expect(projects[0].tap(&:reload).tests_count).to eq(3)
    expect_project_version name: raw_payload[:version], projectId: projects[0].api_id

    # check the 3 new tests
    tests = check_tests projects[0], user, payload do
      check_test name: 'It should work'
      check_test name: 'It might work'
      check_test name: 'It should also work'
    end

    # check the 3 results
    results = check_results raw_payload[:results], payload do
      check_result test: tests[0], newTest: true
      check_result test: tests[1], newTest: true
      check_result test: tests[2], newTest: true
    end

    # check the descriptions of the 3 tests for the payload's project version
    check_descriptions payload, tests do
      check_description results[0], resultsCount: 1
      check_description results[1], resultsCount: 1, passing: false
      check_description results[2], resultsCount: 1
    end
  end

  it "should combine payloads based on the test report uid", probedock: { key: '9otz' } do

    # prepare 2 payloads
    first_raw_payload = generate_raw_payload projects[0], version: '1.2.3', uid: 'foo', results: [
      { n: 'It should work', c: 'RSpec', g: %w(foo) }
    ]

    second_raw_payload = generate_raw_payload projects[0], version: '1.2.3', uid: 'foo', results: [
      { n: 'It might work', p: false, c: 'JUnit'  },
      { n: 'It should also work', g: %w(foo bar) }
    ]

    store_preaction_state

    # publish the 2 payloads
    with_resque do
      api_post '/api/publish', first_raw_payload.to_json, user: user
      expect_http_status_code 202
      @first_response_body = @response_body
      check_json_payload_response @response_body, projects[0], user, first_raw_payload

      api_post '/api/publish', second_raw_payload.to_json, user: user
      expect_http_status_code 202
      check_json_payload_response @response_body, projects[0], user, second_raw_payload
    end

    # check database changes
    expect_changes test_payloads: 2, test_reports: 1, test_results: 3, project_versions: 1, project_tests: 3, test_descriptions: 3, categories: 2, tags: 2

    # check payloads & report
    first_payload = check_json_payload @first_response_body, first_raw_payload, testsCount: 1, newTestsCount: 1
    second_payload = check_json_payload @response_body, second_raw_payload, testsCount: 2, newTestsCount: 2
    check_report first_payload, second_payload, uid: 'foo', organization: organization

    # check project & version
    expect(projects[0].tap(&:reload).tests_count).to eq(3)
    expect_project_version name: '1.2.3', projectId: projects[0].api_id

    # check the 3 new tests
    tests = check_tests projects[0], user, first_payload do
      check_test name: 'It should work'
    end

    tests += check_tests(projects[0], user, second_payload) do
      check_test name: 'It might work'
      check_test name: 'It should also work'
    end

    # check the result of the first payload
    results = check_results first_raw_payload[:results], first_payload do
      check_result test: tests[0], newTest: true
    end

    # check the 2 results of the second payload
    results += check_results second_raw_payload[:results], second_payload do
      check_result test: tests[1], newTest: true
      check_result test: tests[2], newTest: true
    end

    # check the descriptions of the first test for the first payload's project version
    check_descriptions first_payload, tests[0, 1] do
      check_description results[0], resultsCount: 1
    end

    # check the descriptions of the two other tests for the second payload's project version
    check_descriptions second_payload, tests[1, 2] do
      check_description results[1], resultsCount: 1, passing: false
      check_description results[2], resultsCount: 1
    end
  end

  it "should combine test results by key or name", probedock: { key: 'la9t' } do

    # prepare payload with 12 results
    raw_payload = generate_raw_payload projects[0], results: [
      { n: 'It should work', g: %w(foo), c: 'JUnit' },           # 0.  key: bcde (same name as result at index 8)
      { n: 'It might work', p: false, g: %w(bar) },              # 1.  name: It might work
      { n: 'It should also work', k: 'abcd' },                   # 2.  key: abcd
      { n: 'It will work', k: 'cdef', p: false, g: %w(bar) },    # 3.  key: cdef
      { n: 'It should work', g: %w(foo bar), t: %w(t1) },        # 4.  key: bcde (same name as result at index 8)
      { n: 'It would work', p: false, c: 'RSpec' },              # 5.  name: It would work
      { n: 'It should also work', k: 'abcd' },                   # 6.  key: abcd
      { n: 'It could work', k: 'bcde', p: false, g: %w(baz) },   # 7.  key: bcde
      { n: 'It should work', k: 'bcde', t: %w(t1 t2 t3) },       # 8.  key: bcde
      { n: 'It will definitely work', k: 'cdef', g: %w(baz) },   # 9.  key: cdef
      { n: 'It would work', p: false },                          # 10. name: It would work
      { n: 'It could work', c: 'RSpec' }                         # 11. key: bcde (same name as result at index 7)
    ]

    store_preaction_state

    # publish payload
    with_resque do
      api_post '/api/publish', raw_payload.to_json, user: user
      expect_http_status_code 202
      check_json_payload_response @response_body, projects[0], user, raw_payload
    end

    # check database changes
    expect_changes test_payloads: 1, test_reports: 1, project_versions: 1, test_keys: 3, test_results: 12, project_tests: 5, test_descriptions: 5, categories: 2, tags: 3, tickets: 3

    # check payload & report
    payload = check_json_payload @response_body, raw_payload, testsCount: 5, newTestsCount: 5
    check_report payload, organization: organization

    # check project & version
    expect(projects[0].tap(&:reload).tests_count).to eq(5)
    expect_project_version name: raw_payload[:version], projectId: projects[0].api_id

    # check the 5 new tests
    tests = check_tests projects[0], user, payload do
      check_test name: 'It might work'
      check_test name: 'It would work', resultsCount: 2
      check_test name: 'It should also work', key: 'abcd', resultsCount: 2
      check_test name: 'It will definitely work', key: 'cdef', resultsCount: 2
      check_test name: 'It could work', key: 'bcde', resultsCount: 5
    end

    # check the 12 results
    results = check_results raw_payload[:results], payload do
      check_result test: tests[4], newTest: true
      check_result test: tests[0], newTest: true
      check_result test: tests[2], newTest: true
      check_result test: tests[3], newTest: true
      check_result test: tests[4], newTest: true
      check_result test: tests[1], newTest: true
      check_result test: tests[2], newTest: true
      check_result test: tests[4], newTest: true
      check_result test: tests[4], newTest: true
      check_result test: tests[3], newTest: true
      check_result test: tests[1], newTest: true
      check_result test: tests[4], newTest: true
    end

    # check the descriptions of the 5 tests for the payload's project version
    check_descriptions payload, tests do
      check_description results[1], resultsCount: 1, passing: false
      check_description results[10], resultsCount: 2, passing: false, category: 'RSpec'
      check_description results[6], resultsCount: 2
      check_description results[9], resultsCount: 2, passing: false, tags: %w(bar baz)
      check_description results[11], resultsCount: 5, passing: false, category: 'RSpec', tags: %w(foo bar baz), tickets: %w(t1 t2 t3)
    end
  end

  it "should associate results with existing tests", probedock: { key: '9gh8' } do

    tests = []

    categories = %w(RSpec).collect{ |name| create :category, name: name, organization: organization }
    tags = %w(foo bar).collect{ |name| create :tag, name: name, organization: organization }
    tickets = %w(t1).collect{ |name| create :ticket, name: name, organization: organization }

    version = create :project_version, project: projects[0], name: '1.2.3'
    tests << create(:test, name: 'It should work', project: projects[0], last_runner: user, project_version: version, category: categories[0], tags: tags)
    k1 = create :test_key, user: user, project: projects[0]
    tests << create(:test, name: 'It might work', project: projects[0], key: k1, last_runner: user, project_version: version, category: categories[0], tickets: tickets)
    k2 = create :test_key, user: user, project: projects[0]
    tests << create(:test, name: 'It could work', project: projects[0], key: k2, last_runner: user, project_version: version, tags: tags[0, 1])
    tests << create(:test, name: 'It has always worked', project: projects[0], last_runner: user, project_version: version)

    version = create :project_version, project: projects[1], name: '1.2.3'
    create :test, name: 'It should work', project: projects[1], last_runner: user, project_version: version
    k3 = create :test_key, user: user, project: projects[1], key: k2.key
    create :test, name: 'It could work', project: projects[1], key: k3, last_runner: user, project_version: version

    Project.where(id: projects[0].id).update_all tests_count: ProjectTest.where(project_id: projects[0].id).count

    raw_payload = generate_raw_payload projects[0], version: '1.2.3', results: [
      { n: 'It had worked', p: false },
      { n: 'It should work', c: 'Cucumber', g: %w(baz) },
      { n: 'It might work', k: k1.key, g: %w(foo bar baz), t: %w(t1 t2 t3) },
      { n: 'It will work', p: false },
      { n: 'It could work', k: k2.key, c: 'RSpec' },
      { n: 'It will work', k: k2.key, t: %w(t2 t3) },
      { n: 'It had worked', k: 'foo', p: false },
      { n: 'It has always worked', k: 'bar' }
    ]

    store_preaction_state

    # publish payload
    with_resque do
      api_post '/api/publish', raw_payload.to_json, user: user
      expect_http_status_code 202
      check_json_payload_response @response_body, projects[0], user, raw_payload
    end

    # check database changes
    expect_changes test_payloads: 1, test_reports: 1, test_results: 8, test_keys: 2, project_tests: 1, test_descriptions: 1, categories: 1, tags: 1, tickets: 2

    # check payload & report
    payload = check_json_payload @response_body, raw_payload, testsCount: 5, newTestsCount: 1
    check_report payload, organization: organization

    # check project & version
    expect(projects[0].tap(&:reload).tests_count).to eq(5)
    expect_project_version name: raw_payload[:version], projectId: projects[0].api_id

    # check the 4 existing tests and the new test
    tests = check_tests projects[0], user, payload do
      check_test name: 'It should work', test: tests[0]
      check_test name: 'It might work', key: k1.key, resultsCount: 1, test: tests[1]
      check_test name: 'It will work', key: k2.key, resultsCount: 3, test: tests[2]
      tests << check_test(name: 'It had worked', key: 'foo', resultsCount: 2)
      check_test name: 'It has always worked', key: 'bar', resultsCount: 1, test: tests[3]
    end

    # check the 8 results
    results = check_results raw_payload[:results], payload do
      check_result test: tests[3], newTest: true
      check_result test: tests[0], newTest: false
      check_result test: tests[1], newTest: false
      check_result test: tests[2], newTest: false
      check_result test: tests[2], newTest: false
      check_result test: tests[2], newTest: false
      check_result test: tests[3], newTest: true
      check_result test: tests[4], newTest: false
    end

    # check the descriptions of the 5 tests for the project version
    check_descriptions payload, tests do
      check_description results[1], resultsCount: 1
      check_description results[2], resultsCount: 1
      check_description results[5], resultsCount: 3, passing: false, category: 'RSpec'
      check_description results[6], resultsCount: 2, passing: false
      check_description results[7], resultsCount: 1
    end
  end

  it "should associate results of a new version with existing tests", probedock: { key: '2i9w' } do

    tests = []

    v1 = create :project_version, project: projects[0], name: '1.1.2'
    tests << create(:test, name: 'It should work', project: projects[0], last_runner: user, project_version: v1)

    v2 = create :project_version, project: projects[0], name: '1.2.3'
    k1 = create :test_key, user: user, project: projects[0]
    tests << create(:test, name: 'It might work', project: projects[0], key: k1, last_runner: user, project_version: v2)
    k2 = create :test_key, user: user, project: projects[0]
    tests << create(:test, name: 'It could work', project: projects[0], key: k2, last_runner: user, project_version: v2)
    tests << create(:test, name: 'It has always worked', project: projects[0], last_runner: user, project_version: v2)

    v3 = create :project_version, project: projects[1], name: '1.3.4'
    create :test, name: 'It should work', project: projects[1], last_runner: user, project_version: v3
    k3 = create :test_key, user: user, project: projects[1], key: k2.key
    create :test, name: 'It could work', project: projects[1], key: k3, last_runner: user, project_version: v3

    Project.where(id: projects[0].id).update_all tests_count: ProjectTest.where(project_id: projects[0].id).count

    raw_payload = generate_raw_payload projects[0], version: '1.3.4', results: [
      { n: 'It had worked', p: false },
      { n: 'It should work' },
      { n: 'It might work', k: k1.key },
      { n: 'It will work', p: false },
      { n: 'It could work' }, # FIXME: move this result down one line and check why it doesn't work
      { n: 'It will work', k: k2.key },
      { n: 'It had worked', k: 'foo', p: false },
      { n: 'It has always worked', k: 'bar' },
      { n: 'It has always worked' }
    ]

    store_preaction_state

    # publish payload
    with_resque do
      api_post '/api/publish', raw_payload.to_json, user: user
      expect_http_status_code 202
      check_json_payload_response @response_body, projects[0], user, raw_payload
    end

    # check payload & report
    payload = check_json_payload @response_body, raw_payload, testsCount: 5, newTestsCount: 1
    check_report payload, organization: organization

    # check database changes
    expect_changes test_payloads: 1, test_reports: 1, test_results: 9, project_versions: 1, test_keys: 2, project_tests: 1, test_descriptions: 5

    # check project & version
    expect(projects[0].tap(&:reload).tests_count).to eq(5)
    expect_project_version name: raw_payload[:version], projectId: projects[0].api_id

    # check the 4 existing tests and the new test
    tests = check_tests projects[0], user, payload do
      check_test name: 'It should work', test: tests[0]
      check_test name: 'It might work', key: k1.key, resultsCount: 1, test: tests[1]
      check_test name: 'It will work', key: k2.key, resultsCount: 3, test: tests[2]
      check_test name: 'It had worked', key: 'foo', resultsCount: 2
      check_test name: 'It has always worked', key: 'bar', resultsCount: 2, test: tests[3]
    end

    # check the 9 results
    results = check_results raw_payload[:results], payload do
      check_result test: tests[3], newTest: true
      check_result test: tests[0], newTest: false
      check_result test: tests[1], newTest: false
      check_result test: tests[2], newTest: false
      check_result test: tests[2], newTest: false
      check_result test: tests[2], newTest: false
      check_result test: tests[3], newTest: true
      check_result test: tests[4], newTest: false
      check_result test: tests[4], newTest: false
    end

    # check the descriptions of the 5 tests for the project version
    check_descriptions payload, tests do
      check_description results[1], resultsCount: 1
      check_description results[2], resultsCount: 1
      check_description results[5], resultsCount: 3, passing: false
      check_description results[6], resultsCount: 2, passing: false
      check_description results[8], resultsCount: 2
    end
  end

  it "should not assign contributions to tests run by a technical user for the first time and with no test key", probedock: { key: '35of' } do

    tests = []

    version = create :project_version, project: projects[0], name: '1.2.3'
    tests << create(:test, name: 'It might work', project: projects[0], last_runner: user, project_version: version)
    k1 = create :test_key, user: user, project: projects[0]

    Project.where(id: projects[0].id).update_all tests_count: ProjectTest.where(project_id: projects[0].id).count

    raw_payload = generate_raw_payload projects[0], version: '1.2.3', results: [
      { n: 'It had worked', p: false },
      { n: 'It should work' },
      { n: 'It might work', k: k1.key }
    ]

    technical_user = create :technical_user, organization: organization

    store_preaction_state

    # publish payload
    with_resque do
      api_post '/api/publish', raw_payload.to_json, user: technical_user
      expect_http_status_code 202
      check_json_payload_response @response_body, projects[0], technical_user, raw_payload
    end

    # check database changes
    expect_changes test_payloads: 1, test_reports: 1, test_results: 3, project_tests: 2, test_descriptions: 2

    # check payload & report
    payload = check_json_payload @response_body, raw_payload, testsCount: 3, newTestsCount: 2
    check_report payload, organization: organization

    # check project & version
    expect(projects[0].tap(&:reload).tests_count).to eq(3)
    expect_project_version name: raw_payload[:version], projectId: projects[0].api_id

    # check the existing test and the 2 new tests
    tests = check_tests projects[0], technical_user, payload do
      check_test name: 'It had worked'
      check_test name: 'It should work'
      check_test name: 'It might work', key: k1.key, test: tests[0]
    end

    # check the 3 results
    results = check_results raw_payload[:results], payload do
      check_result test: tests[0], newTest: true
      check_result test: tests[1], newTest: true
      check_result test: tests[2], newTest: false
    end

    # check the descriptions of the 3 tests for the project version
    check_descriptions payload, tests do
      check_description results[0], resultsCount: 1, passing: false, contributions: []
      check_description results[1], resultsCount: 1, contributions: []
      check_description results[2], resultsCount: 1, contributions: [ { kind: :key_creator, userId: user.api_id } ]
    end
  end
end
