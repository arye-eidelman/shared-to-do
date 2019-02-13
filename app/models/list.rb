class List < ApplicationRecord
  has_many :items
  has_many :lists_users, dependent: :destroy
  has_many :users, through: :lists_users
  validates :name, presence: true, length: { in: 1..100 }

  def items_attributes=(items_attributes)
    self.items.destroy_all
    items_attributes.each do |i, item_attributes|
      if item_attributes[:name].present?
        self.items.build(item_attributes)
      end
    end
  end

  scope :shared,     -> { where(id: ListsUser.shared_list_ids) }
  scope :non_shared, -> { where(id: ListsUser.non_shared_list_ids) }

  scope :owned_by, ->(user) { where(id: ListsUser.where(user: user).is_owner) }
  scope :not_owned_by, ->(user) { where(id: ListsUser.where(user: user).is_not_owner) }

  def owner
    lists_users.find_by(is_owner: true).user
  end

  def collaborators
    lists_users.is_not_owner.map(&:user)
  end

  def shared?
    lists_users.count > 1
  end

  def share_with(users)
    users.map{ |user| lists_users.create(user: user, is_owner: false) }
  end

  def unshare(users)
    lists_users.where(user: users, is_owner: false).destroy_all
  end

  def unshare_all
    lists_users.where(is_owner: false).destroy_all
  end
end
