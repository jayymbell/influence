class PasswordValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?

    unless value.match?(/[A-Z]/)
      record.errors.add(attribute, :no_upper_case, message: "must contain at least one uppercase letter")
    end

    unless value.match?(/[a-z]/)
      record.errors.add(attribute, :no_lower_case, message: "must contain at least one lowercase letter")
    end

    unless value.match?(/\d/)
      record.errors.add(attribute, :no_digit, message: "must contain at least one number")
    end

    unless value.match?(/[@$!%*?&]/)
      record.errors.add(attribute, :no_special_char, message: "must contain at least one special character (@$!%*?&)")
    end
  end
end