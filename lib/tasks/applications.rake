# encoding: utf-8
namespace :applications do

  desc 'Seeds the T2 applications'
  task :seed => :environment do
    T2Application.delete_all
    applications_attributes = [
      {url: "http://t2allocation.neo.com",       icon: "📊", title: "Allocations",  classes: "allocations"},
      {url: "http://t2utilization.neo.com",      icon: "📈", title: "Utilization"},
      {url: "http://t2people.neo.com",           icon: "👤", title: "Neons"},
      {url: "http://t2projects.neo.com",         icon: "", title: "Projects"}
    ]

    applications_attributes.each_with_index do |attrs, index|
      T2Application.create(attrs.merge(position: index))
    end
  end

  desc 'Seeds the T2 applications in staging'
  task :seed_staging => :environment do
    T2Application.delete_all
    applications_attributes = [
      {url: "http://t2allocation-staging.neo.com",       icon: "📊", title: "Allocations",  classes: "allocations"},
      {url: "http://t2utilization-staging.neo.com",      icon: "📈", title: "Utilization"},
      {url: "http://t2people-staging.neo.com",           icon: "👤", title: "Neons"},
      {url: "http://t2projects-staging.neo.com",         icon: "", title: "Projects"}
    ]

    applications_attributes.each_with_index do |attrs, index|
      T2Application.create(attrs.merge(position: index))
    end
  end

  desc 'Set the default T2 application for everyone'
  task :set_default_for_all => :environment do
    util = T2Application.where(title: 'Allocations').first
    User.find_each { |u| u.t2_application_id = util.id ; u.save }
  end
end
