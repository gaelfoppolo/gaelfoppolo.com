---
title: Archives
---

<p>
{% for post in site.posts %}
  <span>
	{{ post.date | date: "%d/%m/%Y" }} <span class="separator"> &middot; </span>  
	<a href="{{ post.url }}">{{ post.title }}</a>
  </span>
  <br/>
{% endfor %}
</p>