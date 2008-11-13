Geometry.module_eval do
  
  FLAGS = ['', '%', '<', '>', '!']#, '@']
  
  def to_s
    str = ''
    str << "%g" % @width if @width > 0
    str << 'x' if (@width > 0 || @height > 0)
    str << "%g" % @height if @height > 0
    str << "%+d%+d" % [@x, @y] if (@x != 0 || @y != 0)
    str << RFLAGS.index(@flag)
  end
  
  # attempts to get new dimensions for the current geometry string given these old dimensions.
  # This doesn't implement the aspect flag (!) or the area flag (@).  PDI
  def new_dimensions_for(orig_width, orig_height)
    new_width  = orig_width
    new_height = orig_height

    case @flag
      when :percent
        scale_x = @width.zero?  ? 100 : @width
        scale_y = @height.zero? ? @width : @height
        new_width    = scale_x.to_f * (orig_width.to_f  / 100.0)
        new_height   = scale_y.to_f * (orig_height.to_f / 100.0)
      when :<, :>, nil
        scale_factor =
          if new_width.zero? || new_height.zero?
            1.0
          else
            if @width.nonzero? && @height.nonzero?
              [@width.to_f / new_width.to_f, @height.to_f / new_height.to_f].min
            else
              @width.nonzero? ? (@width.to_f / new_width.to_f) : (@height.to_f / new_height.to_f)
            end
          end
        new_width  = scale_factor * new_width.to_f
        new_height = scale_factor * new_height.to_f
        new_width  = orig_width  if @flag && orig_width.send(@flag,  new_width)
        new_height = orig_height if @flag && orig_height.send(@flag, new_height)
      when :aspect
        new_width = @width unless @width.nil?
        new_height = @height unless @height.nil?
    end

    [new_width, new_height].collect! { |v| v.round }
  end
  
end

Technoweenie::AttachmentFu::Processors::MiniMagickProcessor.module_eval do
  
  # Original method by Ian Drysdale, http://tinyurl.com/6rosxu
  def resize_image(img, size)
    size = size.first if size.is_a?(Array) && size.length == 1
    if size.is_a?(Fixnum) || (size.is_a?(Array) && size.first.is_a?(Fixnum))
      if size.is_a?(Fixnum)
        size = [size, size]
        img.resize(size.join('x'))
      else
        img.resize(size.join('x') + '!')
      end
    else
      n_size = [img[:width], img[:height]] / size.to_s
      if size.ends_with? "!"
        aspect = n_size[0].to_f / n_size[1].to_f
        ih, iw = img[:height], img[:width]
        w, h = (ih * aspect), (iw / aspect)
        w = [iw, w].min.to_i
        h = [ih, h].min.to_i
        if ih > h
          shave_off =  ((ih - h) / 2).round
          img.shave("0x#{shave_off}")
        end
        if iw > w
          shave_off = ((iw - w ) / 2).round
          img.shave("#{shave_off}x0")
        end
        img.resize(size.to_s)
      else
        img.resize(size.to_s)
      end
      self.temp_path = img
    end
  end
  
end