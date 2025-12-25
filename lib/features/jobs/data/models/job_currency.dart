class JobCurrency {
  final String id;
  final String code;
  final String symbol;
  final String dir; // left/right

  const JobCurrency({
    required this.id,
    required this.code,
    required this.symbol,
    required this.dir,
  });

  factory JobCurrency.fromJson(Map<String, dynamic> json) {
    return JobCurrency(
      id: (json['currency_id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      dir: (json['dir'] ?? 'left').toString(),
    );
  }

  String format(num amount) {
    final a = amount.toString();
    return dir == 'right' ? '$a $symbol' : '$symbol$a';
  }
}
