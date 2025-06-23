import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double? elevation;
  final Widget? icon;
  final bool isLoading;
  final Color? loadingColor;
  final double? loadingSize;
  final List<BoxShadow>? customShadow;
  final Gradient? gradient;
  final Border? border;
  final bool isOutlined;
  final double? borderWidth;
  final TextAlign? textAlign;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;

  const CustomElevatedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.height = 50,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation = 2,
    this.icon,
    this.isLoading = false,
    this.loadingColor,
    this.loadingSize = 20,
    this.customShadow,
    this.gradient,
    this.border,
    this.isOutlined = false,
    this.borderWidth = 1.5,
    this.textAlign,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Default colors
    final defaultBackgroundColor = isOutlined 
        ? Colors.transparent 
        : backgroundColor ?? Theme.of(context).primaryColor;
    final defaultTextColor = isOutlined 
        ? (textColor ?? Theme.of(context).primaryColor)
        : (textColor ?? Colors.white);
    final defaultBorderColor = borderColor ?? Theme.of(context).primaryColor;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        boxShadow: customShadow ?? (elevation! > 0 && !isOutlined ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: elevation! * 2,
            offset: Offset(0, elevation!),
          ),
        ] : null),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: gradient != null ? Colors.transparent : defaultBackgroundColor,
          foregroundColor: defaultTextColor,
          elevation: gradient != null ? 0 : (isOutlined ? 0 : elevation),
          padding: padding ?? EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            side: isOutlined || border != null
                ? BorderSide(
                    color: defaultBorderColor,
                    width: borderWidth!,
                  )
                : BorderSide.none,
          ),
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? SizedBox(
                width: loadingSize,
                height: loadingSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loadingColor ?? defaultTextColor,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: mainAxisAlignment!,
                crossAxisAlignment: crossAxisAlignment!,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        color: defaultTextColor,
                      ),
                      textAlign: textAlign,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}