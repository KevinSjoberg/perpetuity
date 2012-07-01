# Perpetuity [![Build Status](https://secure.travis-ci.org/jgaskins/perpetuity.png)](http://travis-ci.org/jgaskins/perpetuity)

Perpetuity is a simple Ruby object persistence layer that attempts to follow Martin Fowler's Data Mapper pattern, allowing you to use plain-old Ruby objects in your Ruby apps in order to decouple your domain logic from the database as well as speed up your tests. There is no need for your model classes to inherit from another class or even include a mix-in.

Your objects will hopefully eventually be able to be persisted into whichever database you like. Right now, only MongoDB is supported. Other persistence solutions will come later.

This gem was inspired by [a blog post by Steve Klabnik](http://blog.steveklabnik.com/posts/2011-12-30-active-record-considered-harmful).

## How it works

In the Data Mapper pattern, the objects you work with don't understand how to persist themselves. This decouples them from the database and allows you to write your code without it in mind. We achieve this goal using Mappers.

## Installation

Add the following to your Gemfile and run `bundle` to install it.

```ruby
gem 'perpetuity', github: 'jgaskins/perpetuity'
```

Once it's got enough functionality to release, you'll be able to remove the git parameter.

## Configuration

The only currently supported persistence method is MongoDB. Other schemaless solutions can probably be implemented easily.

```ruby
mongodb = Perpetuity::MongoDB.new host: 'mongodb.example.com', db: 'example_db'
Perpetuity.configure do 
  data_source mongodb
end
```

## Saving Objects

```ruby
class Article
  attr_accessor :title, :body
end

class ArticleMapper < Perpetuity::Mapper
  attribute :title, String
  attribute :body, String
end

article = Article.new
article.title = 'New Article'
article.body = 'This is an article.'

ArticleMapper.insert article
```

## Loading Objects

You can load all persisted objects of a particular class by invoking the `all` method on that class's mapper class. Example:

```ruby
ArticleMapper.all
```

You can load specific objects by calling the `find` method with an ID param on that class's mapper class and passing in the criteria. You may also specify more general criteria using the `select` method with a block similar to `Enumerable#select`.

```ruby
article = ArticleMapper.find params[:id]
users = UserMapper.select { email == 'me@example.com' }
articles = ArticleMapper.select { published_at < Time.now }
comments = CommentMapper.select { article_id.in articles.map(&:id) }
```

This will return a Perpetuity::Retrieval object, which will lazily retrieve the objects from the database. They will wait to hit the DB when you begin iterating over the objects so you can continue chaining methods.

```ruby
articles = ArticleMapper.select { published_at < Time.now }
articles = articles.sort(:published_at).reverse
articles = articles.page(2).per_page(10) # built-in pagination

articles.each do |article| # This is when the DB gets hit
  # Display the pretty articles
end
```

## Associations with Other Objects

If an object references another object (such as an article referencing its author), it must have a relationship identifier in its mapper class. For example:

```ruby
class User
end

class Article
  attr_accessor :author

  def initialize(author)
    self.author = author
  end
end

class UserMapper < Perpetuity::Mapper
end

class ArticleMapper < Perpetuity::Mapper
  attribute :author, User
end
```

This allows you to write the following:

```ruby
article = ArticleMapper.first
ArticleMapper.load_association! article, :author
user = article.author
```

## Customizing persistence

Setting the ID of a record to a custom value rather than using the DB default.

```ruby
class ArticleMapper < Perpetuity::Mapper
  id { title.gsub(/\W+/, '-') } # use the article's parameterized title attribute as its ID
end
```

## Contributing

Right now, this code is pretty bare and there are possibly some design decisions that need some more refinement. You can help. If you have ideas to build on this, send some love in the form of pull requests or issues or tweets or e-mails and I'll do what I can for them.
