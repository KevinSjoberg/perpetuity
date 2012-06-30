class Article
  attr_accessor :title, :body, :comments
  def initialize title="Title", body="Body", author=nil
    @title = title
    @body = body
    @comments = []
  end
end

class ArticleMapper < Perpetuity::Mapper
  attribute :title, String
  attribute :body, String
  attribute :comments, Array
end

class Comment
  attr_reader :body
  def initialize body='Body'
    @body = body
  end
end

class CommentMapper < Perpetuity::Mapper
  attribute :body, String
end

class User
  attr_accessor :name
  def initialize name="Foo"
    @name = name
  end
end

class UserMapper < Perpetuity::Mapper
  attribute :name, String
end

class Book
  attr_accessor :title
  def initialize title="Foo Bar"
    @title = title
  end
end

class BookMapper < Perpetuity::Mapper
  id { title.gsub(/\W+/, '-').downcase }
  attribute :title, String
end

class Message
  def initialize text="My Message!"
    self.text = text
  end

  def text
    @text.reverse
  end

  def text= new_text
    @text = new_text.reverse
  end
end

class MessageMapper < Perpetuity::Mapper
  attribute :text, String
end

class EmptyMapper < Perpetuity::Mapper
end
