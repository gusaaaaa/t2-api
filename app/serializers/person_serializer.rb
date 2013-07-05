class PersonSerializer < ActiveModel::Serializer
  attributes :id, :name, :notes, :email, :unsellable, :office_id, :start_date, :end_date
  has_many :allocations, embed: :ids
end
