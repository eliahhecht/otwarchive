class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :subscribable, :polymorphic => true
  
  validates_presence_of :user
  
  # Get the subscriptions associated with this work
  # currently: users subscribed to work, users subscribed to creator of work
  scope :for_work, lambda {|work|
    where(["(subscribable_id = ? AND subscribable_type = 'Work') 
            OR (subscribable_id IN (?) AND subscribable_type = 'User')
            OR (subscribable_id IN (?) AND subscribable_type = 'Series')",
            work.id, 
            work.pseuds.value_of(:user_id),
            work.series.value_of(:id)]).
    group(:user_id)
  }
  
  # The name of the object to which the user is subscribed
  def name
    if subscribable.respond_to?(:login)
      subscribable.login
    elsif subscribable.respond_to?(:name)
      subscribable.name
    elsif subscribable.respond_to?(:title)
      subscribable.title
    end
  end
  
  def subject_text(creation)
    authors = creation.pseuds.map{ |p| p.byline }.to_sentence
    if creation.is_a?(Chapter)
      "#{creation.work.title} by #{authors} has been updated"
    elsif subscribable_type == 'User'
      "#{self.name} has posted #{creation.title}"
    elsif subscribable_type == 'Series'
      verb = creation.pseuds.length > 1 ? 'have' : 'has'
      "#{authors} #{verb} updated the '#{self.name}' series"
    end
  end
  
end
