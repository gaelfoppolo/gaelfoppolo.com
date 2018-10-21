---
title: Categories
---

<p>
<span class="tags taglist smallTag">
   	{% for category in site.categories %}
		{% assign category_name = category[0] %}
  		<a href="{{ site.baseurl }}/category/{{ category_name | url_encode }}" alt="{{ category_name }}">{{ category_name }}</a>
	{% endfor %}
</span>
</p>