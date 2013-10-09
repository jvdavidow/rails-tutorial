## Comments Checkpoint

* Comments must be associated with users, so add a user_id foreign key to the `comments` table. Don't forget to add an index to it as well:

```bash
$ rails g migration AddUserToComments user_id:integer:index
$ rake db:migrate
```

* Update the `User` model so that you can call `user.comments`:

```ruby
# user.rb
has_many :comments
```

* Comments will only need to be created for now, so generate a `comments_controller` with the appropriate action;

```bash
$ rails g controller Comments create
```

* Write a `create` method in the `comments_controller`:

```ruby
class CommentsController < ApplicationController
  def create
    @topic = Topic.find(params[:topic_id])
    @post = @topic.posts.find(params[:post_id])
    @comments = @post.comments

    @comment = current_user.comments.build(params[:comment])
    @comment.post = @post
    
    authorize! :create, @comment, message: "You need be signed in to do that."
    if @comment.save
      flash[:notice] = "Comment was created."
      redirect_to [@topic, @post]
    else
      flash[:error] = "There was an error saving the comment. Please try again."
      render 'posts/show'
    end
  end
end
```

* Modify the `seeds.rb` file to create comments when you `db:reset`:

```ruby
post_count = Post.count
User.all.each do |user|
  rand(30..50).times do
    p = Post.find(rand(1..post_count))
    c = user.comments.create(
      body: Faker::Lorem.paragraphs(rand(1..2)).join("\n"),
      post: p)
    c.update_attribute(:created_at, Time.now - rand(600..31536000))
  end
end
```

* You'll need to show comments with posts, so modify the `posts_controller` to provide `comments` to the `posts/show.html.erb`:

```ruby
# posts_controller.rb

  def show
    @topic = Topic.find(params[:topic_id])
    @post = Post.find(params[:id])
    @comments = @post.comments
    @comment = Comment.new
  end
```

* Nest the `comments` resource under `post` in `routes.rb`. Remember that you only have one `comment` action for now (`create`), so only create the routes that you need:

```ruby
  resources :topics do
    resources :posts, except: [:index] do
      resources :comments, only: [:create]
    end
  end
```

* Update `models/ability.rb` to allow members to manage comments:

```ruby
    if user.role? :member
      can :manage, Post, :user_id => user.id
      can :manage, Comment, :user_id => user.id
    end
```

* Create a comment partial to display comments associated with a post:

> Create `views/comments/_comment.html.erb`

```html
<div class="media">
  <%= link_to '#', class: 'pull-left' do %>
    <%= image_tag(comment.user.avatar.small.url) if comment.user.avatar? %>
  <% end %>
  <div class="media-body">
    <small><%= comment.user.name %> commented <%= time_ago_in_words(comment.created_at) %> ago</small>
    <p><%= comment.body %></p>
  </div>
</div>
```

* Create a comment form partial so users can submit new comments on a post:

> Create `views/comments/_form.html.erb`

```html
<%= form_for [topic, post, comment], htm: { class: 'form-horizontal' } do |f| %>
  <% if comment.errors.any? %>
    <div class="alert alert-block">
      <h4>There are <%= pluralize(comment.errors.count, "error") %> errors.</h4>
      <ul>
        <% comment.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>
  <%= control_group_tag(comment.errors[:body]) do %>
    <div class="controls">
      <%= f.text_area :body, rows: 8 %>
    </div>
  <% end %>
  <div class="control-group">
    <div class="controls">
      <%= f.submit "Add Comment", class: 'btn' %>
    </div>
  </div>
<% end %>
```

* Update the `Post` `show` view to render the comment partials:

```html
...
    <p><%= markdown @post.body %></p>
    <p><%= image_tag(@post.image_url) if @post.image? %></p>
    <hr/>

    <h2><%= @comments.count %> Comments</h2>
    
    <%= render @comments %>
    
    <% if can? :create, Comment %>
      <hr/>
      <h4>New Comment</h4>
      <%= render partial: 'comments/form', locals: { topic: @topic, post: @post, comment: @comment } %>
    <% end %>
...    
```

* Add validations to the `Comment` model so that comments are at least `5` characters and the `body` is always present:

```ruby
# comment.rb

class Comment < ActiveRecord::Base
  belongs_to :post
  belongs_to :user
  attr_accessible :body, :post

  validates :body, length: { minimum: 5 }, presence: true
  validates :user, presence: true
end
```
