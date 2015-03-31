# courtesy of abhishekkr
# https://gist.github.com/abhishekkr/3610174#file-term_color-rb
# get colored terminal output using these String methods

class String

  def colortxt(txt, term_color_code)
    "\e[#{term_color_code}m#{txt}\e[0m"
  end

  def bold;               colortxt(self, 1);    end
  def thin;               colortxt(self, 2);    end
  def underline;          colortxt(self, 4);    end
  def blink;              colortxt(self, 5);    end
  def highlight;          colortxt(self, 7);    end
  def hidden;             colortxt(self, 8);    end
  def strikethrough;      colortxt(self, 9);    end

  def black;              colortxt(self, 30);   end
  def red;                colortxt(self, 31);   end
  def green;              colortxt(self, 32);   end
  def yellow;             colortxt(self, 33);   end
  def blue;               colortxt(self, 34);   end
  def magenta;            colortxt(self, 35);   end
  def cyan;               colortxt(self, 36);   end
  def white;              colortxt(self, 37);   end

  def default;            colortxt(self, 39);   end

  def black_bg;           colortxt(self, 40);   end
  def red_bg;             colortxt(self, 41);   end
  def green_bg;           colortxt(self, 42);   end
  def yellow_bg;          colortxt(self, 43);   end
  def blue_bg;            colortxt(self, 44);   end
  def magenta_bg;         colortxt(self, 45);   end
  def cyan_bg;            colortxt(self, 46);   end
  def white_bg;           colortxt(self, 47);   end

  def default_bg;         colortxt(self, 49);   end

  def grey;               colortxt(self, 90);   end

  def bright_red;         colortxt(self, 91);   end
  def bright_green;       colortxt(self, 92);   end
  def bright_yellow;      colortxt(self, 93);   end
  def bright_blue;        colortxt(self, 94);   end
  def bright_magenta;     colortxt(self, 95);   end
  def bright_cyan;        colortxt(self, 96);   end
  def bright_white;       colortxt(self, 97);   end

  def grey_bg;            colortxt(self, 100);  end

  def bright_red_bg;      colortxt(self, 101);  end
  def bright_green_bg;    colortxt(self, 102);  end
  def bright_yellow_bg;   colortxt(self, 103);  end
  def bright_blue_bg;     colortxt(self, 104);  end
  def bright_magent_bg;   colortxt(self, 105);  end
  def bright_cyan_bg;     colortxt(self, 106);  end
  def bright_white_bg;    colortxt(self, 107);  end
end
