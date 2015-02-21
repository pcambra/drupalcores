#!/usr/bin/env ruby

log_args = ARGV[0] || '--since=2011-03-09'
git_command = 'git --git-dir=../drupalcore/.git --work-tree=drupal log 8.0.x ' + log_args + ' -s --format=%s'

Encoding.default_external = Encoding::UTF_8
require 'erb'
require 'yaml'
require 'json'

name_mappings = YAML::load_file('../config/name_mappings.yml')
contributors = Hash.new(0)
commits = Array.new
reverts = Array.new

%x[#{git_command}].split("\n").each do |c|
  issue_number = c.scan(/#([0-9]+)/)
  if issue_number.empty? == false || c.index('Issue') == 0
    if c.index('Revert') == 0 then
      reverts.push(issue_number)
    else
      commits.push(c)
    end
  end
end

commits.each_with_index do |c, i|
  if r = reverts.index{ |item| item == c.scan(/#([0-9]+)/) }
    commits.delete_at(i)
    reverts.delete_at(r)
  end
end

commits.each do |m|
  m.gsub(/\-/, '_').scan(/\s(?:by\s?)([[:word:]\s,.|]+):/i).each do |people|
    people[0].split(/(?:,|\||\band\b|\bet al(?:.)?)/).each do |p|
      name = p.strip.downcase
      contributors[name_mappings[name] || name] += 1 unless p.nil?
    end
  end
end

contributors = Hash[contributors.sort_by {|k, v| v }.reverse]

output = {
  :date => Time.new,
  :count => contributors.length,
  :graph => {
    :one => contributors.select {|k,v| v < 2}.length,
    :twoTen => contributors.select {|k,v| (v > 1 && v < 11) }.length,
    :TenOver => contributors.select {|k,v| v > 10}.length
  },
  :contributors => contributors
}

puts output.to_json
