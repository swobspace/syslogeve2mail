#!/usr/bin/env ruby

require 'json'
require 'yaml'
require 'rb-inotify'
require 'action_mailer'
require 'dotenv'
Dotenv.load

logfile = ARGV.first || '/var/log/messages'

# ---------------------------------------------------------
# Mailer
# ---------------------------------------------------------

ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.delivery_method = :sendmail
ActionMailer::Base.view_paths= File.dirname(__FILE__)

class Mailer < ActionMailer::Base
  default from: ENV['MAIL_FROM'], to: ENV['MAIL_TO']

  def boot
    mail(subject: "Starting syslogeve2mail ...")
  end

  def alert_mail(ids)
    @ids = ids
    @alrt = ids['alert']
    subject  = "#{ids['sensor']}:[#{@alrt['gid']}:#{@alrt['signature_id']}:#{@alrt['rev']}]"
    subject += " #{@alrt['signature']}/#{@alrt['category']}/#{@alrt['severity']}: "
    subject += "#{ids['proto']} #{ids['src_ip']}:#{ids['src_port']} -> #{ids['dest_ip']}:#{ids['dest_port']}"

    mail(subject: subject)
  end

  def unparsable(sensor, bulk)
    @bulk = bulk
    subject = "#{sensor}: unparsable content"
    mail(subject: subject)
  end
end

Mailer.boot.deliver_now

# ---------------------------------------------------------
# Main
# ---------------------------------------------------------

open(logfile, 'r') do |file|
  file.seek(0, IO::SEEK_END)		# rewind
  queue = INotify::Notifier.new
  queue.watch(logfile, :modify) do |event|
    sleep 3
    file.each_line do |line|
      next unless line =~ /suricata.*"timestamp"/
      m = line.match(/\A([A-Za-z]{3} [ 0-9]{2} \d\d:\d\d:\d\d) (\w+) suricata\[\d+\]: (\{.+\})/)
      begin
        hash = JSON.parse(m[3])
        hash['sensor'] = m[2]
        email = Mailer.alert_mail(hash)
        puts email
        email.deliver_now
      rescue
        email = Mailer.unparsable(m[2], line)
        puts email
        email.deliver_now
      end
    end
  end
  queue.run
end
