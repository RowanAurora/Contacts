class SessionPersistence
  def initialize(session)
    @session = session
    session[:contacts] ||= []
  end

# Returns the category that is checked in this session
  def checked_category
    @session[:category]
  end

# Changes the category selected in session
  def update_checked_category(update_check)
    @session[:category] = update_check
  end

# Clears selected category
  def remove_checked_category
    @session.delete(:category)
  end
end