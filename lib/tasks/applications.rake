# encoding: utf-8
namespace :applications do

  desc 'Seeds the T2 applications'
  task :seed => :environment do
    T2Application.delete_all
    applications_attributes = [
      {url: "http://t2-allocation.herokuapp.com",       icon: "📊", title: "Allocations",  classes: "allocations"},
      {url: "http://t2-utilization.herokuapp.com",      icon: "📈", title: "Utilization"},
      {url: "http://brockman.herokuapp.com",            icon: "", title: "Pipeline"},
      {url: "http://t2-people.herokuapp.com",           icon: "👤", title: "Neons"}
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
