
# Syntax sugar

class Object
  # Provide is_bool? to all objects
  def is_bool?
    [ true, false ].include? self
  end
end
