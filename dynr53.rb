#!/usr/bin/ruby

require 'aws-sdk'

records = [
  "record1.nil",
  "sub1.record1.nil",
  "sub2.record1.nil",
  "sub3.record1.nil"
]

$zoneid = "<your route53 zone id>"
$ttl = 300
$comment = "Auto upddated @ " +  `date`
$ip = `curl -ss https://icanhazip.com/`
$ip = $ip.strip

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new('<your IAM ID key>', '<your IAM ID secret>')
})

def getCurrentIP(record)
  route53 = Aws::Route53::Client.new()

  resp = route53.list_resource_record_sets({
    hosted_zone_id: $zoneid,
    start_record_name: record,
  })

  return resp.resource_record_sets[0].resource_records[0].value
end

def getRecordInfo(record)
  route53 = Aws::Route53::Client.new()

  resp = route53.list_resource_record_sets({
    hosted_zone_id: $zoneid,
    start_record_name: record,
  })

  return resp.resource_record_sets
end

def changeIP(record,newip)
  route53 = Aws::Route53::Client.new()
  resp = route53.change_resource_record_sets({
    hosted_zone_id: $zoneid, # required
    change_batch: { # required
      comment: $comment,
      changes: [ # required
        {
          action: "UPSERT", # required, accepts CREATE, DELETE, UPSERT
          resource_record_set: { # required
            name: record, # required
            type: "A", # required, accepts SOA, A, TXT, NS, CNAME, MX, PTR, SRV, SPF, AAAA
            ttl: $ttl,
            resource_records: [
              {
                value: newip, # required
              },
            ],
          },
        },
      ],
    },
  })

  return resp.change_info.status
end

records.each do |record|
  currentip = getCurrentIP(record)
  puts "#{$ip} == #{currentip}"
  if $ip == currentip
    puts "IP has not changed for #{record}"
  else
    changeIP(record,$ip)
    puts "IP changed to #{$ip} for #{record}"
  end
end
