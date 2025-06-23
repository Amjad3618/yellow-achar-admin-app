
import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final TextAlign? textAlign;
  final TextDecoration? decoration;
  final Color? decorationColor;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final FontStyle? fontStyle;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  final TextStyle? customStyle;

  const CustomText(
    this.text, {
    Key? key,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.fontFamily,
    this.textAlign,
    this.decoration,
    this.decorationColor,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.fontStyle,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.customStyle,
  }) : super(key: key);

  // Convenience constructors for common styles
  const CustomText.heading(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.fontFamily,
    this.decoration,
    this.decorationColor,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.fontStyle,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.customStyle,
  }) : fontSize = 24.0,
       fontWeight = FontWeight.bold,
       super(key: key);

  const CustomText.subheading(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.fontFamily,
    this.decoration,
    this.decorationColor,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.fontStyle,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.customStyle,
  }) : fontSize = 18.0,
       fontWeight = FontWeight.w600,
       super(key: key);

  const CustomText.body(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.fontFamily,
    this.decoration,
    this.decorationColor,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.fontStyle,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.customStyle,
  }) : fontSize = 16.0,
       fontWeight = FontWeight.normal,
       super(key: key);

  const CustomText.caption(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.fontFamily,
    this.decoration,
    this.decorationColor,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.fontStyle,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.customStyle,
  }) : fontSize = 12.0,
       fontWeight = FontWeight.w400,
       super(key: key);

  const CustomText.bold(
    this.text, {
    Key? key,
    this.fontSize,
    this.color,
    this.fontFamily,
    this.textAlign,
    this.decoration,
    this.decorationColor,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.fontStyle,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.customStyle,
  }) : fontWeight = FontWeight.bold,
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
      style: customStyle ??
          TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            decoration: decoration,
            decorationColor: decorationColor,
            letterSpacing: letterSpacing,
            wordSpacing: wordSpacing,
            height: height,
            fontStyle: fontStyle,
          ),
    );
  }
}