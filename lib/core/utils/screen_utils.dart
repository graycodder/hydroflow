import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScreenUtils {
  static void init(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
    );
  }

  // Width
  static double w(double width) => width.w;

  // Height
  static double h(double height) => height.h;

  // Font Size
  static double sp(double fontSize) => fontSize.sp;

  // Radius
  static double r(double radius) => radius.r;

  // Horizontal Padding
  static double setWidth(double width) => ScreenUtil().setWidth(width);

  // Vertical Padding
  static double setHeight(double height) => ScreenUtil().setHeight(height);

  // Screen Width
  static double get screenWidth => ScreenUtil().screenWidth;

  // Screen Height
  static double get screenHeight => ScreenUtil().screenHeight;
}

extension ResponsiveSize on num {
  double get sw => this.w;
  double get sh => this.h;
  double get ssp => this.sp;
  double get sr => this.r;
}
