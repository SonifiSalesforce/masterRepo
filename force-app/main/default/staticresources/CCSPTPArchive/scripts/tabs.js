setTimeout(function() {
    $('.psTabgroup > div').hide();
    $('.psTabgroup > div:first-of-type').show();
    $('.psTabs a').click(
        function(e) {
            e.preventDefault();
            var $this = $(this),
                tabgroup = '#' + $this.parents('.psTabs').data('tabgroup'),
                others = $this.closest('li').siblings().children('a'),
                target = $this.attr('href');
            others.removeClass('active');
            $this.addClass('active');
            $(tabgroup).children('div').hide();
            $(target).show();
        });
}, 500);
