import 'package:flutter/material.dart';

const primaryColor = Color(0xFF1479f5);
const secondaryColor = Color(0xFF1479f5);

const LinearGradient backgroundColor = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color.fromARGB(255, 176, 212, 255),
    Color(0xFFfcfdff),
  ],
  stops: [0.1, 0.3], 
); 

const primaryTextColor = Color(0xFF142747);
const secondaryTextColor = Color(0xFF5679ba);
const pirmaryColorElementBG = Color(0xFFfcfdff);

// Extended design tokens for Treatment & Hardware readings
const successColor = Color(0xFF2E7D32);
const warningColor = Color(0xFFED6C02);
const dangerColor = Color(0xFFD32F2F);

const cardShadow = [
  BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  ),
];
