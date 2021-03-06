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
# encoding: UTF-8
require 'spec_helper'

describe TestResult, probedock: { tags: :unit } do

  describe "#passed?" do
    it "should indicate whether the test has passed", probedock: { key: 'huhz' } do
      subject.passed = true
      expect(subject.passed?).to be(true)
      subject.passed = false
      expect(subject.passed?).to be(false)
    end
  end

  describe "#active?" do
    it "should indicate whether the test is active", probedock: { key: 'bbyg' } do
      subject.active = true
      expect(subject.active?).to be(true)
      subject.active = false
      expect(subject.active?).to be(false)
    end
  end

  describe "#new_test?" do
    it "should indicate whether the test is new", probedock: { key: 'am2x' } do
      subject.new_test = true
      expect(subject.new_test?).to be(true)
      subject.new_test = false
      expect(subject.new_test?).to be(false)
    end
  end

  describe "#custom_values" do
    it "should return the result's custom values if set", probedock: { key: 'tlzd' } do
      subject.custom_values = { 'foo' => 'bar', 'baz' => 'qux' }
      expect(subject.custom_values).to eq({ 'foo' => 'bar', 'baz' => 'qux' })
    end

    it "should return an empty hash if no custom values are set", probedock: { key: '904k' } do
      subject.custom_values = nil
      expect(subject.custom_values).to eq({})
      subject.custom_values = {}
      expect(subject.custom_values).to eq({})
    end
  end

  describe "validations" do
    it(nil, probedock: { key: 'mnkp' }){ should validate_presence_of(:name) }
    it(nil, probedock: { key: 've3e' }){ should validate_length_of(:name).is_at_most(255) }
    it(nil, probedock: { key: 'ab57dcb4d8c3' }){ should allow_value(true, false).for(:passed) }
    it(nil, probedock: { key: '9ba0a4f7cba9' }){ should_not allow_value(nil, 'abc', 123).for(:passed) }
    it(nil, probedock: { key: 'a736baaeb6c5' }){ should validate_presence_of(:project_version) }
    it(nil, probedock: { key: '07a3e2a83e69' }){ should validate_presence_of(:duration) }
    it(nil, probedock: { key: '2c24629f7508' }){ should validate_numericality_of(:duration).only_integer }
    it(nil, probedock: { key: 'e30d02a9bf0b' }){ should allow_value(0, 10000, 3600000).for(:duration) }
    it(nil, probedock: { key: 'ad86f100aa50' }){ should_not allow_value(-1, -42, -66).for(:duration) }
    it(nil, probedock: { key: '2acec8d868b3' }){ should validate_length_of(:message).is_at_most(65535) }
    it(nil, probedock: { key: 'eb74444c0250' }){ should validate_presence_of(:run_at) }
    it(nil, probedock: { key: '512d38de3e73' }){ should validate_presence_of(:runner) }
    it(nil, probedock: { key: 'ffa2bc12ab4a' }){ should validate_presence_of(:test) }
    it(nil, probedock: { key: '437888444049' }){ should validate_presence_of(:test_payload) }
    it(nil, probedock: { key: 'ro68' }){ should validate_presence_of(:payload_index) }
    it(nil, probedock: { key: '655398ed00bc' }){ should allow_value(true, false).for(:active) }
    it(nil, probedock: { key: '3108c4643221' }){ should_not allow_value(nil, 'abc', 123).for(:active) }
  end

  describe "associations" do
    it(nil, probedock: { key: 'a0f0857cf4a2' }){ should belong_to(:runner).class_name('User') }
    it(nil, probedock: { key: 'ecb3ec9ae70a' }){ should belong_to(:test).class_name('ProjectTest') }
    it(nil, probedock: { key: 'd6c73fc4ea8c' }){ should belong_to(:test_payload) }
    it(nil, probedock: { key: '98276100d0b6' }){ should belong_to(:category) }
    it(nil, probedock: { key: 'h3hq' }){ should belong_to(:key).class_name('TestKey') }
    it(nil, probedock: { key: 'dsvk' }){ should belong_to(:project_version) }
    it(nil, probedock: { key: 'e1y5' }){ should have_and_belong_to_many(:tags) }
    it(nil, probedock: { key: 'kcpf' }){ should have_and_belong_to_many(:tickets) }
  end

  describe "database table" do
    it(nil, probedock: { key: 'l5lm' }){ should have_db_columns(:id, :name, :passed, :duration, :message, :active, :new_test, :payload_properties_set, :custom_values, :runner_id, :test_id, :test_payload_id, :payload_index, :project_version_id, :key_id, :category_id, :created_at, :run_at) }
    it(nil, probedock: { key: '8deb8afbca16' }){ should have_db_column(:id).of_type(:integer).with_options(null: false) }
    it(nil, probedock: { key: 's0ce' }){ should have_db_column(:name).of_type(:string).with_options(null: false, limit: 255) }
    it(nil, probedock: { key: '099c43427c69' }){ should have_db_column(:passed).of_type(:boolean).with_options(null: false) }
    it(nil, probedock: { key: '558aec64f22d' }){ should have_db_column(:duration).of_type(:integer).with_options(null: false) }
    it(nil, probedock: { key: '516ef9ba84ea' }){ should have_db_column(:message).of_type(:text) }
    it(nil, probedock: { key: 'e9f576c1cc45' }){ should have_db_column(:active).of_type(:boolean).with_options(null: false) }
    it(nil, probedock: { key: '0ffbb1a73cb7' }){ should have_db_column(:new_test).of_type(:boolean).with_options(null: false) }
    it(nil, probedock: { key: 'janx' }){ should have_db_column(:payload_properties_set).of_type(:integer).with_options(null: false, default: 0) }
    it(nil, probedock: { key: '0yi7' }){ should have_db_column(:custom_values).of_type(:json) }
    it(nil, probedock: { key: 'f27560967967' }){ should have_db_column(:runner_id).of_type(:integer).with_options(null: false) }
    it(nil, probedock: { key: '93d491c4e31f' }){ should have_db_column(:test_id).of_type(:integer).with_options(null: true) }
    it(nil, probedock: { key: '556726a1c0cc' }){ should have_db_column(:test_payload_id).of_type(:integer).with_options(null: false) }
    it(nil, probedock: { key: 'rj7d' }){ should have_db_column(:payload_index).of_type(:integer).with_options(null: false) }
    it(nil, probedock: { key: 'c5fa090e339b' }){ should have_db_column(:project_version_id).of_type(:integer).with_options(null: false) }
    it(nil, probedock: { key: 'gf10' }){ should have_db_column(:key_id).of_type(:integer) }
    it(nil, probedock: { key: '7c2f23a0d69f' }){ should have_db_column(:category_id).of_type(:integer).with_options(null: true) }
    it(nil, probedock: { key: '8e2d652a897e' }){ should have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it(nil, probedock: { key: '9383fe626ffc' }){ should have_db_column(:run_at).of_type(:datetime).with_options(null: false) }
  end
end
