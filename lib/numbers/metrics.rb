class Metrics
  def initialize(all_users = nil, active_users = nil)
    @all = all_users
    @all_active = active_users    
  end

  def accounts_count
    [[:total, all.size]]
  end

  def accounts_count_by_state
    [[:active, all_active.size],
      [:suspended, all.select {|u| not u.suspended_at.nil? }.size]]
  end

  def active_accounts_count_by_role
    count_values(all_active.group_by(&:role))
  end

  def active_accounts_count_by_application
    enabled_applications_for_each_user = all_active.map {|u| u.permissions.select {|p| p.permissions.include?("signin") }.map {|p| p.application.name } }.flatten
    count_values(enabled_applications_for_each_user.group_by(&:to_s))
  end

  def active_accounts_count_by_organisation
    count_values(all_active.group_by {|u| u.organisation ? u.organisation.name : 'None assigned' })
  end

  def active_admin_user_names
    ["admin", "superadmin"].collect do |role|
      [role, all_active.select {|u| u.role == role }.map {|u| "#{u.name} <#{u.email}>" }.sort.join(", ")]
    end
  end

  def accounts_count_by_days_since_last_sign_in
    [0...7, 7...15, 15...30, 30...45, 45...60, 60...90, 90...180, 180...10000000].inject([]) do |result, range|
      count_days_since_last_sign_in = all_active.select {|u| u.current_sign_in_at && range.last.days.ago <= u.current_sign_in_at && u.current_sign_in_at < range.first.days.ago }.size
      result << ["#{range.first} - #{range.last}", count_days_since_last_sign_in]
      result 
    end + [["never signed in", all_active.select {|u| u.current_sign_in_at.nil? }.size]]
  end

  def accounts_count_how_often_user_has_signed_in
    [0, 1, 2...5, 5...10, 10...25, 25...50, 50...100, 100...200, 200...10000000].inject([]) do |result, range_or_value|
      if range_or_value.is_a?(Range)
        range = range_or_value
        result << ["#{range.first} - #{range.last}", all_active.select {|u| range.include?(u.sign_in_count) }.size ]
      else
        result << ["#{range_or_value} time(s)", all_active.select {|u| u.sign_in_count == range_or_value}.size]
      end
      result 
    end
  end

  def active_accounts_count_by_email_domain
    count_values(all_active.group_by {|u| u.email.split("@")[1] })
  end

  def to_a
    metric_methods.map do |metric|
      send(metric).map {|result| [metric.to_s.humanize, result].flatten }
    end.flatten(1)
  end

  private
  def has_signin_permissions?(permission)
    permission.permissions.include?("signin")
  end

  def count_values(map)
    map.inject({}) do |new_map, key_and_value|
      key, value = key_and_value
      new_map[key] = value.size
      new_map
    end
  end

  def all
    @all ||= User.includes({permissions: :application}, :organisation).all
  end

  def all_active
    @all_active ||= User.active.includes({permissions: :application}, :organisation).to_a
  end

  def metric_methods
    public_methods(false) - [:to_a]
  end
end
