class SessionPersistence
  def initialize(session)
    @session = session
    session[:contacts] ||= []
  end

  def checked_category
    @session[:category]
  end

  def update_checked_category(update_check)
    @session[:category] = update_check
  end

  def remove_checked_category
    @session.delete(:category)
  end

  def all_contacts
    @session[:contacts]
  end

  def single_contact(id)
    @session[:contacts][id]
  end

  def add_contact(contact_info)
    @session[:contacts] << contact_info
  end

  def update_single_contact(id, contact_info)
    @session[:contacts][id] = contact_info
  end

  def delete_contact(id)
    @session[:contacts].delete_at(id)
  end
end