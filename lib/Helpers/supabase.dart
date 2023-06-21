/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2022, Ankit Sangwan
 */

import 'package:supabase/supabase.dart';

class SupaBase {
  final SupabaseClient client = SupabaseClient(
    'https://axilwxdcqocnvxqsrbsi.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF4aWx3eGRjcW9jbnZ4cXNyYnNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NTU3OTE1NDksImV4cCI6MTk3MTM2NzU0OX0.BZJ4YGyp6mWAgVqvgnglRJYAYNgNFe9xRFHKgbUi9FA',
  );

  Future<Map> getUpdate() async {
    final response =
        await client.from('Update').select().order('LatestVersion').execute();
    final List result = response.data as List;
    return result.isEmpty
        ? {}
        : {
            'LatestVersion': response.data[0]['LatestVersion'],
            'LatestUrl': response.data[0]['LatestUrl'],
            'arm64-v8a': response.data[0]['arm64-v8a'],
            'armeabi-v7a': response.data[0]['armeabi-v7a'],
            'universal': response.data[0]['universal'],
            'app': response.data[0]['app']
          };
  }

  Future<void> updateUserDetails(
    String? userId,
    String key,
    dynamic value,
  ) async {
    final response = await client.from('Users').update(
      {key: value},
      returning: ReturningOption.minimal,
    ).match({'id': userId}).execute();
    // ignore: avoid_print
    print(response.toJson());
  }

  Future<int> createUser(Map data) async {
    final response = await client
        .from('Users')
        .insert(data, returning: ReturningOption.minimal)
        .execute();
    return response.status ?? 404;
  }
}
