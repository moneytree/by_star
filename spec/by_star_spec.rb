require File.join(File.dirname(__FILE__), 'spec_helper')
require 'by_star'

describe Post do
  
  def stub_time
    year = Time.zone.now.year
    Time.stub!(:now).and_return("15-05-#{year}".to_time)
  end
  
  def find(*args)
    method = description_args.first.sub(' ', '_')
    Post.send(method, *args)
  end
  
  def size(*args)
    method = description_args.first.sub(' ', '_')
    Post.send(method, *args).size
  end
  
  
  describe "by year" do
    it "should be able to find all the posts in the current year" do
      size.should eql(Post.count - 1)
    end
    
    it "should be able to find if given a string" do
      size(Time.now.year.to_s).should eql(Post.count - 1)
    end
    
    it "should be able to find a single post from last year" do
      size(Time.zone.now.year-1).should eql(1)
    end
    
    it "should error when given an invalid year" do
      lambda { find(1901) }.should raise_error(ByStar::ParseError, "Invalid arguments detected, year may possibly be outside of valid range (1902-2039)")
      lambda { find(2039) }.should raise_error(ByStar::ParseError, "Invalid arguments detected, year may possibly be outside of valid range (1902-2039)")
    end
    
    it "should be able to use an alternative field" do
      Event.by_year(nil, :field => "start_time").size.should eql(7)
    end
  end
  
  describe "by month" do
    
    it "should be able to find a post for the current month" do
      size.should eql(Time.zone.now.month+6)
    end
  
    it "should be able to find a single post for January" do
      size("January").should eql(1)
    end
  
    it "should be able to find two posts for the 2nd month" do
      size(2).should eql(2)
    end
  
    it "should be able to find three posts for the 3rd month, using time instance" do
      # Hack... if we're running this test during march there's going to be more posts than usual.
      # This is due to the #today, #yesterday and #tomorrow methods.
      
      size(Time.local(Time.zone.now.year, 3, 1)).should eql(3)
    end
  
    it "should be able to find a single post from January last year" do
      size("January", :year => Time.zone.now.year - 1).should eql(1)
    end
    
    it "should fail when given incorrect months" do
      lambda { find(0) }.should raise_error(ByStar::ParseError)
      lambda { find(13) }.should raise_error(ByStar::ParseError)
      lambda { find("Ryan") }.should raise_error(ByStar::ParseError)
      lambda { find([1,2,3]) }.should raise_error(ByStar::ParseError)
    end
    
    it "should be able to take decimals" do
      size(1.5).should eql(1)
    end
    
    it "should be able to use an alternative field" do
      Event.by_month(nil, :field => "start_time").size.should eql(3)
    end
    
    it "should be able to specify the year as a string" do
      size(1, :year => (Time.zone.now.year - 1).to_s).should eql(1)
    end
    
  end
  
  describe "by fortnight" do
    
    it "should be able to find posts in the current fortnight" do
      stub_time
      size.should eql(3)
    end
    
    it "should be able to find posts in the 1st fortnight" do
      size(0).should eql(1)
    end
    
    it "should be able to find posts for a fortnight ago" do
      stub_time
      size(2.weeks.ago).should eql(5)
    end
    
    it "should raise an error when given an invalid argument" do
      lambda { find(27) }.should raise_error(ByStar::ParseError, "by_fortnight takes only a Time or Date object, a Fixnum (less than or equal to 26) or a Chronicable string.")
    end
    
    it "should be able to use an alternative field" do
      Event.by_fortnight(nil, :field => "start_time").size.should eql(1)
    end
  end
  
  describe "by week" do
    
    it "should be able to find posts in the current week" do
      stub_time
      size.should eql(3)
    end
    
    it "should be able to find posts in the 1st week" do
      size(0).should eql(1)
    end
    
    it "should be able to find posts in the 1st week of last year" do
      size(0, :year => Time.zone.now.year-1).should eql(1)
    end
    
    it "should not find any posts from a week ago" do  
      stub_time
      size(1.week.ago).should eql(0)
    end
    
    it "should be able to find posts by a given date" do
      stub_time
      size(1.week.ago.to_date).should eql(0)
    end
    
    it "should raise an error when given an invalid argument" do
      lambda { find(54) }.should raise_error(ByStar::ParseError, "by_week takes only a Time or Date object, a Fixnum (less than or equal to 53) or a Chronicable string.")
    end
    
    it "should be able to use an alternative field" do
      Event.by_week(nil, :field => "start_time").size.should eql(1)
    end
    
    it "should find posts at the start of the year" do
      size(0).should eql(1)
    end
    
    it "should find posts at the end of the year" do
      size(Time.zone.now.end_of_year).should eql(1)
    end
    
  end
  
  describe "by weekend" do
    it "should be able to find the posts on the weekend of the 1st May" do
      year = Time.zone.now.year
      Time.stub!(:now).and_return("1-08-#{year}".to_time)
      size.should eql(8)
    end
    
    it "should be able to use an alternative field" do
      year = Time.zone.now.year
      Time.stub!(:now).and_return("1-08-#{year}".to_time)
      Event.by_weekend(nil, :field => "start_time").size.should eql(1)
    end
  end
  
  describe "by day" do
    it "should be able to find a post for today" do
      size.should eql(2)
    end
    
    it "should be able to find a post by a given date" do
      size(Date.today).should eql(2)
    end
    
    it "should be able to use an alternative field" do
      Event.by_day(nil, :field => "start_time").size.should eql(1)
    end
  end

  describe "today" do
    it "should show the post for today" do
      find.map(&:text).should include("Today's post")
    end
    
    it "should show the post for tomorrow" do
      find("tomorrow").map(&:text).should include("Tomorrow's post")
    end
    
    it "should be able to use an alternative field" do
      # Test may occur on an event day.
      stub_time
      Event.today(nil, :field => "start_time").size.should eql(0)
    end
  end
  
  describe "yesterday" do
    it "should show the post for yesterday" do
      find.map(&:text).should include("Yesterday's post")
    end
    
    it "should be able find yesterday, given a Date" do
      find(Date.today).map(&:text).should include("Yesterday's post")
    end
    
    it "should be able to use an alternative field" do
      # Test may occur on an event day.
      stub_time
      Event.yesterday(nil, :field => "start_time").size.should eql(0)
    end
    
  end
  
  describe "tomorrow" do
    it "should show the post for tomorrow" do
      find.map(&:text).should include("Tomorrow's post")
    end
    
    it "should be able find tomorrow, given a Date" do
      find(Date.today).map(&:text).should include("Tomorrow's post")
    end
    
    it "should be able to use an alternative field" do
      # Test may occur on an event day.
      stub_time
      Event.tomorrow(nil, :field => "start_time").size.should eql(0)
    end
  end
  
  describe "past" do
    
    before do
      stub_time
    end
    
    it "should show the correct number of posts in the past" do
      size.should eql(16)
    end
    
    it "should find for a given time" do
      size(Time.now - 2.days).should eql(16)
    end
    
    it "should find for a given date" do
      size(Date.today - 2).should eql(16)
    end
    
    it "should find for a given string" do
      size("next tuesday").should eql(19)
    end
    
    it "should be able to find all events before Ryan's birthday using a non-standard field" do
      Event.past("04-12-#{Time.now.year}".to_time, :field => "start_time").size.should eql(6)
    end 
    
  end
  
  describe "future" do
    before do
      stub_time
    end
    
    it "should show the correct number of posts in the future" do
      size.should eql(71)
    end
    
    it "should find for a given date" do
      size(Date.today - 2).should eql(73)
    end
    
    it "should find for a given string" do
      size("next tuesday").should eql(70)
    end
    
    it "should be able to find all events after Dad's birthday using a non-standard field" do
      Event.past("05-07-#{Time.now.year}".to_time, :field => "start_time").size.should eql(3)
    end
  end
  
  describe "as of" do
    it "should be able to find posts as of 2 weeks ago" do
      year = Time.zone.now.year
      Time.stub!(:now).and_return("15-05-#{year}".to_time)
      Post.as_of_2_weeks_ago.size.should eql(7)
    end
    
    it "should not do anything if given an invalid date" do
      lambda { Post.as_of_ryans_birthday }.should raise_error(RuntimeError, "Chronic couldn't work out \"Ryans birthday\"; please be more precise.")
    end
  end
  
  describe "between" do
    it "should find posts between last tuesday and next tuesday" do
      stub_time
      size("last tuesday", "next tuesday").should eql(3)
    end
    
    it "should find  between two times" do
      stub_time
      size(Time.now - 5.days, Time.now + 5.days).should eql(3)
    end
    
    it "should find between two dates" do
      stub_time
      size(Date.today, Date.today + 5).should eql(3)
    end
  end
  
  describe "up to" do
    it "should be able to find posts up to 2 weeks from now" do
      year = Time.zone.now.year
      Time.stub!(:now).and_return("15-05-#{year}".to_time)
      Post.up_to_6_weeks_from_now.size.should eql(9)
    end
    
    it "should not do anything if given an invalid date" do
      lambda { Post.up_to_ryans_birthday }.should raise_error(RuntimeError, "Chronic couldn't work out \"Ryans birthday\"; please be more precise.")
    end
      
  end
  
  # Because we override method_missing, we ensure that it still works as it should with this test.
  describe "method_missing" do
    it "should still work" do
      Post.find_by_text("Today's post").should_not be_nil
    end
    
    it "should raise a proper NoMethodError" do
      lambda { Post.idontexist }.should raise_error(NoMethodError, %r(^undefined method `idontexist'))
    end
  end
  
  
  describe "nested find" do
  
    it "should be able to find a single post from last year with the tag 'ruby'" do
      Post.by_year(Time.zone.now.year - 1) do
        { :include => :tags, :conditions => ["tags.name = ?", 'ruby'] }
      end.size.should eql(1)
    end
    
    it "should be able to find a single post from January last year with the tag 'ruby'" do
      Post.by_month("January", :year => Time.zone.now.year - 1) do
        { :include => :tags, :conditions => ["tags.name = ?", 'ruby'] }
      end.size.should eql(1)
    end
    
    it "should be able to find a single post from the current fortnight with the tag 'may2'" do
      stub_time
      Post.by_fortnight do
        { :include => :tags, :conditions => ["tags.name = ?", 'may2'] }
      end.size.should eql(1)
    end
    
    it "should be able to find a single post from the current week with the tag 'may2'" do
      stub_time
      Post.by_week do
        { :include => :tags, :conditions => ["tags.name = ?", 'may2'] }
      end.size.should eql(1)
    end
    
    it "should be able to find a single post from the current weekend with the tag 'weekend'" do
      stub_time
      Post.by_weekend do
        { :include => :tags, :conditions => ["tags.name = ?", 'weekend'] }
      end.size.should eql(1)
    end
    
    it "should be able to find a single post from the current day with the tag 'today'" do
      Post.by_day do
        { :include => :tags, :conditions => ["tags.name = ?", 'today'] }
      end.size.should eql(1)
    end
    
    it "should be able to find a single post from yesterday with the tag 'yesterday'" do
      Post.yesterday do
        { :include => :tags, :conditions => ["tags.name = ?", 'yesterday'] }
      end.size.should eql(1)
    end
    
    
    it "should be able to find a single post from tomorrow with the tag 'tomorrow'" do
      Post.tomorrow do
        { :include => :tags, :conditions => ["tags.name = ?", 'tomorrow'] }
      end.size.should eql(1)
    end
    
    it "should be able to find a single post from the past with the tag 'yesterday'" do
      Post.past do
        { :include => :tags, :conditions => ["tags.name = ?", 'yesterday'] }
      end.size.should eql(1)
    end
    
    it "should be able to find a single post from the future with the tag 'tomorrow'" do
      Post.future do
        { :include => :tags, :conditions => ["tags.name = ?", 'tomorrow'] }
      end.size.should eql(1)
    end
    
    
    
  end
  
end